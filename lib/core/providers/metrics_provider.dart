import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_connector.dart';
import '../ble/ble_gatt.dart';
import '../ble/ble_models.dart';
import '../gatt/gatt_structs.dart';
import '../gatt/gatt_uuids.dart';
import 'device_provider.dart';

/// Shared GATT subscribe-and-parse logic for notification providers.
/// Subscribes to [charUuid], filters by [expectedSize], and maps via [parser].
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
  final stream = await gatt.subscribe(charUuid);
  yield* stream
      .where((data) => data.length == expectedSize)
      .map(parser);
}

/// Live STATUS notify stream parsed into QosStatus.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>(
  (ref) => _gattNotifyStream(ref,
    charUuid: GattUuids.status,
    expectedSize: QosStatus.size,
    parser: QosStatus.fromBytes,
  ),
);

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
