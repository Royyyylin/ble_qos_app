import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/domain/connection_mode.dart';
import 'package:ble_qos_app/core/providers/device_provider.dart';

void main() {
  group('ConnectedDevice', () {
    test('given_connected_device_when_created_then_stores_mac_field', () {
      final cd = ConnectedDevice(
        id: 'stable-id-123',
        name: 'GW-1',
        mode: ConnectionMode.gwAggregate,
        role: ManufacturerData.roleGateway,
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(cd.id, 'stable-id-123');
      expect(cd.mac, 'AA:BB:CC:DD:EE:FF');
    });
  });

  group('ConnectedDeviceNotifier', () {
    test('given_scanned_device_with_mac_when_connect_then_carries_mac', () {
      final notifier = ConnectedDeviceNotifier();
      final scanned = ScannedDevice(
        id: 'stable-id-456',
        name: 'GW-Test',
        rssi: -55,
        smoothedRssi: -55.0,
        status: DeviceStatus.online,
        lastSeen: DateTime.now(),
        mac: 'AA:BB:CC:DD:EE:FF',
        mfgData: ManufacturerData(
          protocolVersion: 1,
          role: ManufacturerData.roleGateway,
          networkId: 1,
        ),
      );
      notifier.connect(scanned);
      expect(notifier.debugState?.mac, 'AA:BB:CC:DD:EE:FF');
      expect(notifier.debugState?.id, 'stable-id-456');
    });
  });
}
