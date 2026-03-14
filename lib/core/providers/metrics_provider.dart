import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_gatt.dart';
import '../gatt/gatt_structs.dart';
import '../gatt/gatt_uuids.dart';
import 'ble_provider.dart';
import 'device_provider.dart';

/// Live STATUS notify stream parsed into QosStatus.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const Stream.empty();

  final ble = ref.watch(bleInstanceProvider);
  final gatt = BleGatt(ble);
  return gatt
      .subscribe(device.id, GattUuids.status)
      .where((data) => data.length == QosStatus.size)
      .map((data) => QosStatus.fromBytes(data));
});

/// Live EVT notify/indicate stream parsed into QosEvtV1.
final evtStreamProvider = StreamProvider.autoDispose<QosEvtV1>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const Stream.empty();

  final ble = ref.watch(bleInstanceProvider);
  final gatt = BleGatt(ble);
  return gatt
      .subscribe(device.id, GattUuids.evt)
      .where((data) => data.length == QosEvtV1.size)
      .map((data) => QosEvtV1.fromBytes(data));
});

/// Live METRICS notify stream parsed into QosMetricsV2.
final metricsStreamProvider = StreamProvider.autoDispose<QosMetricsV2>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const Stream.empty();

  final ble = ref.watch(bleInstanceProvider);
  final gatt = BleGatt(ble);
  return gatt
      .subscribe(device.id, GattUuids.metricsV2)
      .where((data) => data.length == QosMetricsV2.size)
      .map((data) => QosMetricsV2.fromBytes(data));
});
