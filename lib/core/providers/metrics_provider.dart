import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_connector.dart';
import '../ble/ble_gatt.dart';
import '../ble/ble_models.dart';
import '../gatt/gatt_structs.dart';
import '../gatt/gatt_uuids.dart';
import 'device_provider.dart';
import 'ed_roster_provider.dart';

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
    // debugPrint('[METRICS] $charUuid read ${data.length} bytes');
    final parsed = _tryParse(data, expectedSize, parser);
    if (parsed != null) yield parsed;
  } catch (e) {
    // debugPrint('[METRICS] $charUuid initial read failed: $e');
  }

  // 2. Subscribe to notifications for live updates
  try {
    final stream = await gatt.subscribe(charUuid);
    yield* stream
        .map((data) {
          // debugPrint('[METRICS] $charUuid notify ${data.length} bytes');
          return data;
        })
        .where((data) => data.length >= expectedSize)
        .map((data) => parser(Uint8List.sublistView(data, 0, expectedSize)));
  } catch (e) {
    // debugPrint('[METRICS] $charUuid subscribe failed: $e');
  }
}

/// Live STATUS notify stream — auto-detects 13-byte full or 4-byte indexed format.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  // Initial read (full 13-byte struct)
  try {
    final data = await gatt.read(GattUuids.status);
    // debugPrint('[METRICS] STATUS read ${data.length} bytes');
    if (data.length >= QosStatus.indexedSize) {
      yield QosStatus.parse(data);
    }
  } catch (e) {
    // debugPrint('[METRICS] STATUS initial read failed: $e');
  }

  // Subscribe to notify (may be 4-byte indexed or 13-byte full)
  try {
    final stream = await gatt.subscribe(GattUuids.status);
    yield* stream
        .where((data) => data.length >= QosStatus.indexedSize)
        .map((data) {
          // debugPrint('[METRICS] STATUS notify ${data.length} bytes');
          final status = QosStatus.parse(data);
          // Feed indexed STATUS into EdStatusMap for Roster tab
          if (data.length < QosStatus.size) {
            ref.read(edStatusMapProvider.notifier).update(status);
          }
          return status;
        });
  } catch (e) {
    // debugPrint('[METRICS] STATUS subscribe failed: $e');
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
