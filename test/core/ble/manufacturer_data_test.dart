// test/core/ble/manufacturer_data_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';

void main() {
  group('ManufacturerData', () {
    test('parse valid GW payload', () {
      // protocol=1, role=0x01(GW per firmware ADV_MFG_ROLE_GW), network_id=0x0001, ed_count=3, ha_role=1(active)
      final bytes = Uint8List.fromList([1, ManufacturerData.roleGateway, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.protocolVersion, 1);
      expect(data.role, ManufacturerData.roleGateway);
      expect(data.networkId, 1);
      expect(data.edCount, 3);
      expect(data.haRole, 1);
    });

    test('parse valid ED payload (shorter)', () {
      // protocol=1, role=0x02(ED per firmware ADV_MFG_ROLE_ED), network_id=0x0002
      final bytes = Uint8List.fromList([1, ManufacturerData.roleEndDevice, 2, 0]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.role, ManufacturerData.roleEndDevice);
      expect(data.networkId, 2);
      expect(data.edCount, isNull);
    });

    test('parse returns null for too-short payload', () {
      final bytes = Uint8List.fromList([1, 2]);
      expect(ManufacturerData.parse(bytes), isNull);
    });

    test('given GW role byte when parsed then isGateway returns true', () {
      final bytes = Uint8List.fromList([1, ManufacturerData.roleGateway, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes)!;
      expect(data.isGateway, isTrue);
      expect(data.isEndDevice, isFalse);
    });

    test('given ED role byte when parsed then isEndDevice returns true', () {
      final bytes = Uint8List.fromList([1, ManufacturerData.roleEndDevice, 2, 0]);
      final data = ManufacturerData.parse(bytes)!;
      expect(data.isEndDevice, isTrue);
      expect(data.isGateway, isFalse);
    });
  });

  group('DeviceRole mapping', () {
    test('given Gateway string when roleFromString then returns 0x01', () {
      expect(ManufacturerData.roleFromString('Gateway'), ManufacturerData.roleGateway);
    });

    test('given End Device string when roleFromString then returns 0x02', () {
      expect(ManufacturerData.roleFromString('End Device'), ManufacturerData.roleEndDevice);
    });

    test('given Central Controller string when roleFromString then returns 0x04', () {
      expect(ManufacturerData.roleFromString('Central Controller'), ManufacturerData.roleCentralController);
    });

    test('given unknown string when roleFromString then throws ArgumentError', () {
      expect(() => ManufacturerData.roleFromString('Unknown'), throwsArgumentError);
    });

    test('given role uint8 when roleName then returns display string', () {
      expect(ManufacturerData.roleName(ManufacturerData.roleGateway), 'Gateway');
      expect(ManufacturerData.roleName(ManufacturerData.roleEndDevice), 'End Device');
      expect(ManufacturerData.roleName(ManufacturerData.roleCentralController), 'Central Controller');
    });
  });
}
