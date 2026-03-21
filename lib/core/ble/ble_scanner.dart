import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gatt/gatt_uuids.dart';
import 'ble_models.dart';
import 'manufacturer_data.dart';

/// BLE scanner with EMA smoothing, stale/offline tracking, and duty cycle — spec §4.1.
class BleScanner {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();
  Timer? _statusTimer;
  Timer? _dutyCycleTimer;
  bool _scanning = false;

  /// EMA alpha — spec §4.1: 0.3 * new + 0.7 * prev.
  static const double emaAlpha = 0.3;

  /// Duty cycle: scan 2s, pause 3s — spec §4.1.
  static const Duration scanWindow = Duration(seconds: 2);
  static const Duration pauseWindow = Duration(seconds: 3);

  /// Status thresholds — spec §4.1.
  static const Duration staleThreshold = Duration(seconds: 10);
  static const Duration offlineThreshold = Duration(seconds: 30);

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
      final id = r.device.remoteId.str;

      // Device name: prefer advName, fallback to platformName
      final advName = r.advertisementData.advName;
      final platformName = r.device.platformName;
      final name = advName.isNotEmpty ? advName : platformName;
      final existing = _devices[id];

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

      _devices[id] = ScannedDevice(
        id: id,
        name: name,
        rssi: r.rssi,
        smoothedRssi: smoothed,
        status: DeviceStatus.online,
        lastSeen: now,
        mfgData: mfgData ?? existing?.mfgData,
        alias: existing?.alias,
      );
    }
    _controller.add(_devices.values.toList());
  }

  /// Update device statuses based on lastSeen time.
  void _updateDeviceStatuses() {
    bool changed = false;
    final now = DateTime.now();
    for (final entry in _devices.entries.toList()) {
      final newStatus = deviceStatusFromLastSeen(entry.value.lastSeen, now: now);
      if (newStatus != entry.value.status) {
        _devices[entry.key] = entry.value.copyWith(status: newStatus);
        changed = true;
      }
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
      removeIfGone: const Duration(seconds: 15),
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
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
