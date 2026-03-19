// test/core/ble/manufacturer_data_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';

void main() {
  group('ManufacturerData', () {
    test('parse valid GW payload', () {
      // protocol=1, role=2(GW), network_id=0x0001, ed_count=3, ha_role=1(active)
      final bytes = Uint8List.fromList([1, 2, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.protocolVersion, 1);
      expect(data.role, 2);
      expect(data.networkId, 1);
      expect(data.edCount, 3);
      expect(data.haRole, 1);
    });

    test('parse valid ED payload (shorter)', () {
      // protocol=1, role=1(ED), network_id=0x0002
      final bytes = Uint8List.fromList([1, 1, 2, 0]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.role, 1);
      expect(data.networkId, 2);
      expect(data.edCount, isNull);
    });

    test('parse returns null for too-short payload', () {
      final bytes = Uint8List.fromList([1, 2]);
      expect(ManufacturerData.parse(bytes), isNull);
    });

    test('isGateway returns true for role 2', () {
      final bytes = Uint8List.fromList([1, 2, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes)!;
      expect(data.isGateway, isTrue);
      expect(data.isEndDevice, isFalse);
    });
  });
}
