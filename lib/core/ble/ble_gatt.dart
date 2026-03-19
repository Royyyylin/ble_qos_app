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
  Stream<Uint8List> subscribe(String charUuid) {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');
    c.setNotifyValue(true);
    return c.onValueReceived.map((data) => Uint8List.fromList(data));
  }
}
