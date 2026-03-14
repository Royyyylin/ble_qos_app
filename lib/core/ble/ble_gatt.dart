import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../gatt/gatt_uuids.dart';

/// Thin wrapper for GATT read/write/subscribe operations.
class BleGatt {
  BleGatt(this._ble);

  final FlutterReactiveBle _ble;

  QualifiedCharacteristic _char(String deviceId, String charUuid) {
    return QualifiedCharacteristic(
      serviceId: Uuid.parse(GattUuids.serviceQos),
      characteristicId: Uuid.parse(charUuid),
      deviceId: deviceId,
    );
  }

  /// Read a characteristic value.
  Future<Uint8List> read(String deviceId, String charUuid) async {
    final data = await _ble.readCharacteristic(_char(deviceId, charUuid));
    return Uint8List.fromList(data);
  }

  /// Write with response (confirmed write).
  Future<void> write(String deviceId, String charUuid, List<int> value) async {
    await _ble.writeCharacteristicWithResponse(
      _char(deviceId, charUuid),
      value: value,
    );
  }

  /// Write without response (fire-and-forget).
  Future<void> writeNoResponse(
      String deviceId, String charUuid, List<int> value) async {
    await _ble.writeCharacteristicWithoutResponse(
      _char(deviceId, charUuid),
      value: value,
    );
  }

  /// Subscribe to notifications/indications.
  Stream<Uint8List> subscribe(String deviceId, String charUuid) {
    return _ble
        .subscribeToCharacteristic(_char(deviceId, charUuid))
        .map((data) => Uint8List.fromList(data));
  }
}
