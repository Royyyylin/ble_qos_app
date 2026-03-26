import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_connector.dart';
import '../ble/ble_gatt.dart';
import '../ble/ble_models.dart';
import '../gatt/caps_v2.dart';
import '../gatt/cmd_v2_service.dart';
import '../gatt/gatt_structs.dart';
import '../gatt/gatt_uuids.dart';
import 'device_provider.dart';
import 'ed_roster_provider.dart';
import 'identity_provider.dart';

/// Parse [data] with [parser], accepting data.length >= [expectedSize].
/// Returns null if data is too short.
T? _tryParse<T>(Uint8List data, int expectedSize, T Function(Uint8List) parser) {
  if (data.length < expectedSize) return null;
  return parser(Uint8List.sublistView(data, 0, expectedSize));
}

/// Shared GATT subscribe-and-parse logic for notification providers.
/// First does a GATT read to get initial value (devices that don't send notify),
/// then subscribes to notifications for live updates.
Stream<T> _gattNotifyStream<T>(
  Ref ref, {
  required String charUuid,
  required int expectedSize,
  required T Function(Uint8List data) parser,
}) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  // 1. Initial read — show data immediately even if device doesn't send notify
  try {
    final data = await gatt.read(charUuid);
    debugPrint('[METRICS] $charUuid read ${data.length} bytes');
    final parsed = _tryParse(data, expectedSize, parser);
    if (parsed != null) yield parsed;
  } catch (e) {
    debugPrint('[METRICS] $charUuid initial read failed: $e');
  }

  // 2. Subscribe to notifications for live updates (throttled to 1Hz max)
  try {
    final stream = await gatt.subscribe(charUuid);
    DateTime lastYield = DateTime.now();
    yield* stream
        .where((data) => data.length >= expectedSize)
        .where((_) {
          final now = DateTime.now();
          if (now.difference(lastYield).inMilliseconds < 1000) return false;
          lastYield = now;
          return true;
        })
        .map((data) => parser(Uint8List.sublistView(data, 0, expectedSize)));
  } catch (e) {
    debugPrint('[METRICS] $charUuid subscribe failed: $e');
  }
}

/// STATUS polling interval — firmware sends only 4-byte indexed notify
/// (zone/profile/phy/tx). Full 13-byte STATUS (rssi/pdr/lat/jit) requires GATT read.
const _statusPollInterval = Duration(seconds: 2);

/// Live STATUS stream — polls full 13-byte STATUS every 2s via GATT read.
/// Also subscribes to 4-byte indexed notifies for edStatusMap updates.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  // Subscribe to 4-byte indexed notifies for edStatusMap (fire-and-forget)
  try {
    final stream = await gatt.subscribe(GattUuids.status);
    stream
        .where((data) => data.length >= QosStatus.indexedSize && data.length < QosStatus.size)
        .listen((data) {
      final indexed = QosStatus.fromIndexedBytes(data);
      ref.read(edStatusMapProvider.notifier).update(indexed);
    });
  } catch (e) {
    debugPrint('[METRICS] STATUS subscribe for edStatusMap failed: $e');
  }

  // Poll full 13-byte STATUS every 2s.
  // Keep last valid (non-zero) reading — firmware sometimes returns 0 between updates.
  QosStatus lastValid = const QosStatus();
  while (true) {
    try {
      final data = await gatt.read(GattUuids.status);
      if (data.length >= QosStatus.indexedSize) {
        final status = QosStatus.parse(data);
        debugPrint('[METRICS] STATUS poll: rssi=${status.rssi} pdr=${status.pdr} lat=${status.latency} len=${data.length}');
        if (status.rssi != 0 || status.pdr != 0 || status.latency != 0) {
          lastValid = status;
        }
        if (lastValid.rssi != 0 || lastValid.pdr != 0 || lastValid.latency != 0) {
          yield lastValid;
        }
      }
    } catch (e) {
      debugPrint('[METRICS] STATUS poll read failed: $e');
      return;
    }
    await Future.delayed(_statusPollInterval);
    if (connector.state != BleConnectionState.connected) return;
  }
});

/// Live EVT notify/indicate stream parsed into QosEvtV1.
final evtStreamProvider = StreamProvider.autoDispose<QosEvtV1>(
  (ref) => _gattNotifyStream(ref,
    charUuid: GattUuids.evt,
    expectedSize: QosEvtV1.size,
    parser: QosEvtV1.fromBytes,
  ),
);

/// Live METRICS notify stream parsed into QosMetricsV2.
final metricsStreamProvider = StreamProvider.autoDispose<QosMetricsV2>(
  (ref) => _gattNotifyStream(ref,
    charUuid: GattUuids.metricsV2,
    expectedSize: QosMetricsV2.size,
    parser: QosMetricsV2.fromBytes,
  ),
);

/// Live HA_HB notify stream parsed into HaHeartbeat.
final haHeartbeatStreamProvider = StreamProvider.autoDispose<HaHeartbeat>(
  (ref) => _gattNotifyStream(ref,
    charUuid: GattUuids.haHb,
    expectedSize: HaHeartbeat.size,
    parser: HaHeartbeat.fromBytes,
  ),
);

/// Live CMD_RESULT notify stream — subscribe for async command responses.
final cmdResultStreamProvider = StreamProvider.autoDispose<CmdResult>(
  (ref) => _gattNotifyStream(ref,
    charUuid: GattUuids.cmdResult,
    expectedSize: CmdResult.size,
    parser: CmdResult.fromBytes,
  ),
);

/// Read ROSTER_LIST snapshot from GATT. Returns all slots (including empty).
final rosterListProvider = FutureProvider.autoDispose<List<RosterEntry>>((ref) async {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const [];

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  try {
    final data = await gatt.read(GattUuids.rosterList);
    debugPrint('[ROSTER] read ${data.length} bytes (${data.length ~/ RosterEntry.entrySize} entries)');
    return RosterEntry.parseList(data);
  } catch (e) {
    debugPrint('[ROSTER] read failed: $e');
    return const [];
  }
});

/// CmdV2Service provider — manages transaction-based commands.
/// Auto-starts CMD_RESULT subscription on creation.
final cmdV2ServiceProvider = Provider.autoDispose<CmdV2Service>((ref) {
  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final service = CmdV2Service(gatt);
  service.startListening();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Read CAPS_V2 from GATT (CBOR map). Falls back to empty CapsV2 if not available.
final capsV2Provider = FutureProvider.autoDispose<CapsV2>((ref) async {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const CapsV2();

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  try {
    final data = await gatt.read(GattUuids.capsV2);
    final caps = CapsV2.fromBytes(data);
    debugPrint('[CAPS_V2] proto=${caps.protoVer} maxEd=${caps.maxEd} hasHa=${caps.hasHa} haState=${caps.haStateLabel}');
    return caps;
  } catch (e) {
    debugPrint('[CAPS_V2] read failed (falling back to defaults): $e');
    return const CapsV2();
  }
});

/// Read FW_VERSION from GATT (one-shot, static).
final fwVersionProvider = FutureProvider.autoDispose<FwVersion?>((ref) async {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return null;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  try {
    final data = await gatt.read(GattUuids.fwVersion);
    if (data.length >= FwVersion.size) {
      final ver = FwVersion.fromBytes(data);
      debugPrint('[DEVICE] FW_VERSION: ${ver.label}');
      return ver;
    }
  } catch (e) {
    debugPrint('[DEVICE] FW_VERSION read failed: $e');
  }
  return null;
});

/// Read DEVICE_ALIAS from GATT after connection. Syncs to local DB cache.
/// Returns the alias string, or null if not set on device.
final deviceAliasProvider = FutureProvider.autoDispose<String?>((ref) async {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return null;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  try {
    final data = await gatt.read(GattUuids.deviceAlias);
    final alias = String.fromCharCodes(data).trim();
    debugPrint('[DEVICE] ALIAS: "${alias.isEmpty ? "(empty)" : alias}"');

    if (alias.isNotEmpty) {
      // Sync to local DB so Scanner can display it while disconnected
      final identityService = ref.read(identityServiceProvider);
      await identityService.setAlias(device.id, alias);
      return alias;
    }
  } catch (e) {
    debugPrint('[DEVICE] ALIAS read failed (char may not exist yet): $e');
  }
  return null;
});

/// Read DEVICE_INFO from GATT, refreshing every 30s for uptime updates.
final deviceInfoProvider = StreamProvider.autoDispose<DeviceInfoGatt?>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  // Read immediately, then every 30s
  while (true) {
    try {
      final data = await gatt.read(GattUuids.deviceInfo);
      if (data.length >= DeviceInfoGatt.size) {
        final info = DeviceInfoGatt.fromBytes(data);
        debugPrint('[DEVICE] uptime=${info.uptimeLabel} resets=${info.resetCount} role=${info.roleLabel}');
        yield info;
      }
    } catch (e) {
      debugPrint('[DEVICE] DEVICE_INFO read failed: $e');
      return; // Stop polling if read fails (disconnected or unsupported)
    }
    await Future.delayed(const Duration(seconds: 30));
    if (connector.state != BleConnectionState.connected) return;
  }
});

/// GW_CFG read provider — read current gateway config.
final gwCfgProvider = FutureProvider.autoDispose<QosGwCfgV2?>((ref) async {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return null;

  // Re-read whenever gwCfgVersion changes
  ref.watch(gwCfgVersionStreamProvider);

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  try {
    final data = await gatt.read(GattUuids.gwCfg);
    if (data.length >= QosGwCfgV2.size) {
      return QosGwCfgV2.fromBytes(data);
    }
  } catch (e) {
    debugPrint('[GW_CFG] read failed: $e');
  }
  return null;
});

/// GW_CFG_VERSION notify stream — monotonic counter incremented on each GW_CFG write.
/// Subscribe to detect external config changes and trigger gwCfgProvider refresh.
final gwCfgVersionStreamProvider = StreamProvider.autoDispose<int>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  // Initial read
  try {
    final data = await gatt.read(GattUuids.gwCfgVersion);
    if (data.length >= 4) {
      final bd = ByteData.sublistView(data);
      yield bd.getUint32(0, Endian.little);
    }
  } catch (e) {
    debugPrint('[GW_CFG_VER] initial read failed: $e');
  }

  // Subscribe for changes
  try {
    final stream = await gatt.subscribe(GattUuids.gwCfgVersion);
    yield* stream
        .where((data) => data.length >= 4)
        .map((data) {
          final bd = ByteData.sublistView(data);
          final ver = bd.getUint32(0, Endian.little);
          debugPrint('[GW_CFG_VER] version=$ver');
          return ver;
        });
  } catch (e) {
    debugPrint('[GW_CFG_VER] subscribe failed: $e');
  }
});

/// PING keep-alive: writes PING characteristic every 20s to reset
/// firmware phone_idle timer (30s timeout). Auto-disposes when
/// DeviceScreen is no longer visible.
final pingKeepAliveProvider = StreamProvider.autoDispose<void>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  if (connector.state != BleConnectionState.connected) return;

  final gatt = BleGatt(connector);
  final pingData = Uint8List(4); // 4-byte timestamp placeholder

  await for (final _ in Stream.periodic(const Duration(seconds: 20))) {
    if (connector.state != BleConnectionState.connected) break;
    try {
      await gatt.writeNoResponse(GattUuids.ping, pingData);
    } catch (_) {
      break;
    }
    yield null;
  }
});
