import '../ble/ble_gatt.dart';
import 'gatt_structs.dart';
import 'gatt_uuids.dart';

/// High-level API for sending CMD characteristic commands to the GW.
/// Wraps payload building + GATT write.
class GattCmdService {
  final BleGatt gatt;

  GattCmdService(this.gatt);

  /// CMD 0x03: Tell GW to connect to specified ED by MAC address.
  Future<void> connectEd(String edMacAddress, {int addrType = 1}) async {
    final payload = CmdCode.buildConnectEdPayload(edMacAddress, addrType: addrType);
    await gatt.write(GattUuids.cmd, payload);
  }

  /// CMD 0x04: Tell GW to disconnect specified ED slot.
  Future<void> disconnectEd(int edIndex) async {
    final payload = CmdCode.buildDisconnectEdPayload(edIndex);
    await gatt.write(GattUuids.cmd, payload);
  }
}
