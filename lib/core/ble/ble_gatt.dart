import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_connector.dart';

/// Thin wrapper for GATT read/write/subscribe operations.
/// Uses the connected device's discovered services from BleConnector.
class BleGatt {
  BleGatt(this._connector);

  final BleConnector _connector;

  BluetoothCharacteristic? _findChar(String charUuid) {
    final services = _connector.services;
    if (services == null) return null;
    final targetGuid = Guid(charUuid);
    for (final svc in services) {
      for (final c in svc.characteristics) {
        if (c.uuid == targetGuid) return c;
      }
    }
    return null;
  }

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
  /// Registers cancelWhenDisconnected guard before enabling notifications
  /// to prevent NotificationLeak on disconnect.
  // ADAPTED: anchor shifted — flutter_blue_plus 1.36.x has cancelWhenDisconnected
  // on BluetoothDevice (not BluetoothCharacteristic). We listen then register guard.
  Future<Stream<Uint8List>> subscribe(String charUuid) async {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');
    await c.setNotifyValue(true);
    final stream = c.onValueReceived.map((data) => Uint8List.fromList(data));
    // Guard: auto-cancel subscription on disconnect (prevents leak)
    final sub = stream.listen(null);
    _connector.device?.cancelWhenDisconnected(sub, next: true);
    // Return a new stream that mirrors the subscription
    final controller = StreamController<Uint8List>();
    sub.onData((data) => controller.add(data));
    sub.onError((e) => controller.addError(e));
    sub.onDone(() => controller.close());
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }
}
