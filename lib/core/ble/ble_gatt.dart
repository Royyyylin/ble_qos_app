import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_connector.dart';
import 'ble_service_utils.dart';

/// Thin wrapper for GATT read/write/subscribe operations.
/// Uses the connected device's discovered services from BleConnector.
class BleGatt {
  BleGatt(this._connector);

  final BleConnector _connector;

  BluetoothCharacteristic? _findChar(String charUuid) =>
      findCharacteristicByUuid(_connector.services, charUuid);

  /// Read a characteristic value.
  Future<Uint8List> read(String charUuid) async {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');
    final data = await c.read();
    return Uint8List.fromList(data);
  }

  /// Write with response (confirmed write).
  Future<void> write(String charUuid, List<int> value) async {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');
    await c.write(value);
  }

  /// Write without response (fire-and-forget).
  Future<void> writeNoResponse(String charUuid, List<int> value) async {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');
    await c.write(value, withoutResponse: true);
  }

  /// Subscribe to notifications/indications.
  /// Registers cancelWhenDisconnected guard BEFORE enabling notifications
  /// to prevent NotificationLeak on disconnect (no race window).
  Future<Stream<Uint8List>> subscribe(String charUuid) async {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');

    // 1. Listen to value stream BEFORE enabling notifications
    final stream = c.onValueReceived.map((data) => Uint8List.fromList(data));
    final controller = StreamController<Uint8List>();
    final sub = stream.listen(
      (data) => controller.add(data),
      onError: (e) => controller.addError(e as Object),
      onDone: () => controller.close(),
    );
    controller.onCancel = () => sub.cancel();

    // 2. Register disconnect guard BEFORE setNotifyValue — no leak window
    _connector.device?.cancelWhenDisconnected(sub, next: true);

    // 3. Now enable notifications (if disconnect races, guard already active)
    await c.setNotifyValue(true);

    return controller.stream;
  }
}
