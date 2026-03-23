import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gatt/gatt_uuids.dart';
import '../identity/device_identity_service.dart';
import '../providers/identity_provider.dart';
import 'ble_models.dart';
import 'manufacturer_data.dart';

/// BLE scanner with EMA smoothing, stale/offline tracking, TTL eviction,
/// and duty cycle — spec §4.1.
/// After identity migration: _devices keyed by StableId, not MAC.
class BleScanner {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();
  Timer? _statusTimer;
  Timer? _dutyCycleTimer;
  bool _scanning = false;
  DeviceIdentityService? _identityService;

  /// Inject DeviceIdentityService for MAC→StableId resolution.
  set identityService(DeviceIdentityService? service) =>
      _identityService = service;

  /// EMA alpha — spec §4.1: 0.3 * new + 0.7 * prev.
  static const double emaAlpha = 0.3;

  /// Duty cycle: scan 2s, pause 3s — spec §4.1.
  static const Duration scanWindow = Duration(seconds: 2);
  static const Duration pauseWindow = Duration(seconds: 3);

  /// Status thresholds — spec §3 (foundations/03-ble-lifecycle.md).
  /// Two-stage: 30s → stale, 120s → offline (evict from list).
  static const Duration staleThreshold = Duration(seconds: 30);
  static const Duration offlineThreshold = Duration(seconds: 120);

  /// QoS service UUID for Dart-layer filtering.
  static final Guid _qosServiceUuid = Guid(GattUuids.serviceQos);

  /// QoS service UUID filter for scan — only discover devices advertising 0x1820.
  static final List<Guid> _qosServiceFilter = [Guid(GattUuids.serviceQos)];

  Stream<List<ScannedDevice>> get devices => _controller.stream;
  List<ScannedDevice> get currentDevices => _devices.values.toList();
  bool get isScanning => _scanning;

  void start({bool dutyCycle = false}) {
    _devices.clear();
    _scanSub?.cancel();
    _statusTimer?.cancel();
    _dutyCycleTimer?.cancel();

    _scanSub = FlutterBluePlus.onScanResults.listen(_onScanResults);

    if (dutyCycle) {
      _startDutyCycleScan();
    } else {
      _startContinuousScan();
    }

    // Periodic status update — check stale/offline every 2s.
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateDeviceStatuses();
    });
  }

  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    for (final r in results) {
      final mac = r.device.remoteId.str;

      // Resolve MAC → StableId via DeviceIdentityService (sync from cache)
      final stableId = _identityService?.resolveOrAssignSync(mac) ?? mac;

      // Device name: prefer advName, fallback to platformName
      final advName = r.advertisementData.advName;
      final platformName = r.device.platformName;
      final name = advName.isNotEmpty ? advName : platformName;
      final existing = _devices[stableId];

      // Parse manufacturer data
      ManufacturerData? mfgData;
      final mfgMap = r.advertisementData.manufacturerData;
      if (mfgMap.isNotEmpty) {
        final entry = mfgMap.entries.first;
        mfgData = ManufacturerData.parse(
          Uint8List.fromList([...entry.value]),
        );
      }

      // EMA smoothing
      final smoothed = emaRssi(r.rssi, existing?.smoothedRssi, alpha: emaAlpha);

      // Software filter: only QoS devices (connectable + advertising UUID 0x1820).
      if (!r.advertisementData.connectable) continue;
      final hasQosUuid = r.advertisementData.serviceUuids.contains(_qosServiceUuid);
      if (!hasQosUuid) continue;

      _devices[stableId] = ScannedDevice(
        id: stableId,
        name: name,
        rssi: r.rssi,
        smoothedRssi: smoothed,
        status: DeviceStatus.online,
        lastSeen: now,
        mfgData: mfgData ?? existing?.mfgData,
        alias: existing?.alias,
        mac: mac,
      );
    }
    _controller.add(_devices.values.toList());
  }

  /// Update device statuses based on lastSeen time.
  /// Evicts devices that have been offline beyond offlineThreshold (TTL Eviction).
  void _updateDeviceStatuses() {
    bool changed = false;
    final now = DateTime.now();
    final toEvict = <String>[];

    for (final entry in _devices.entries.toList()) {
      final newStatus = deviceStatusFromLastSeen(entry.value.lastSeen, now: now);
      if (newStatus == DeviceStatus.offline) {
        // TTL Eviction: remove offline devices from visible list
        toEvict.add(entry.key);
        changed = true;
      } else if (newStatus != entry.value.status) {
        _devices[entry.key] = entry.value.copyWith(status: newStatus);
        changed = true;
      }
    }

    for (final key in toEvict) {
      _devices.remove(key);
    }

    if (changed) {
      _controller.add(_devices.values.toList());
    }
  }

  void _startContinuousScan() {
    _scanning = true;
    FlutterBluePlus.startScan(
      withServices: _qosServiceFilter,
      androidUsesFineLocation: true,
      continuousUpdates: true,
      removeIfGone: offlineThreshold,
    );
  }

  /// Duty cycle scanning: scan [scanWindow], pause [pauseWindow], repeat.
  void _startDutyCycleScan() {
    _scanning = true;
    _dutyCycleTick();
  }

  void _dutyCycleTick() {
    FlutterBluePlus.startScan(
      withServices: _qosServiceFilter,
      androidUsesFineLocation: true,
      timeout: scanWindow,
    );
    _dutyCycleTimer = Timer(scanWindow + pauseWindow, () {
      if (_scanning) _dutyCycleTick();
    });
  }

  Future<void> stop() async {
    _scanning = false;
    _scanSub?.cancel();
    _scanSub = null;
    _statusTimer?.cancel();
    _statusTimer = null;
    _dutyCycleTimer?.cancel();
    _dutyCycleTimer = null;
    await FlutterBluePlus.stopScan();
  }

  Future<void> dispose() async {
    await stop();
    _controller.close();
  }
}

/// Riverpod provider for the scanner.
/// Injects DeviceIdentityService for MAC→StableId resolution.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  try {
    scanner.identityService = ref.watch(identityServiceProvider);
  } catch (_) {
    // identityServiceProvider not yet initialized — scanner works without it
  }
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
