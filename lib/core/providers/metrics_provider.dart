import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_connector.dart';
import '../ble/ble_gatt.dart';
import '../gatt/gatt_structs.dart';
import '../gatt/gatt_uuids.dart';
import 'device_provider.dart';

/// Live STATUS notify stream parsed into QosStatus.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final stream = await gatt.subscribe(GattUuids.status);
  yield* stream
      .where((data) => data.length == QosStatus.size)
      .map((data) => QosStatus.fromBytes(data));
});

/// Live EVT notify/indicate stream parsed into QosEvtV1.
final evtStreamProvider = StreamProvider.autoDispose<QosEvtV1>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final stream = await gatt.subscribe(GattUuids.evt);
  yield* stream
      .where((data) => data.length == QosEvtV1.size)
      .map((data) => QosEvtV1.fromBytes(data));
});

/// Live METRICS notify stream parsed into QosMetricsV2.
final metricsStreamProvider = StreamProvider.autoDispose<QosMetricsV2>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final stream = await gatt.subscribe(GattUuids.metricsV2);
  yield* stream
      .where((data) => data.length == QosMetricsV2.size)
      .map((data) => QosMetricsV2.fromBytes(data));
});
