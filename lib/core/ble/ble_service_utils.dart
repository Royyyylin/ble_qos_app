import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Shared utility for finding a GATT characteristic by UUID across discovered services.
/// Used by both BleConnector (handshake) and BleGatt (read/write/subscribe).
BluetoothCharacteristic? findCharacteristicByUuid(
  List<BluetoothService>? services,
  String charUuid,
) {
  if (services == null) return null;
  final targetGuid = Guid(charUuid);
  for (final svc in services) {
    for (final c in svc.characteristics) {
      if (c.uuid == targetGuid) return c;
    }
  }
  return null;
}
