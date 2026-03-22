import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/identity/device_identity.dart';

void main() {
  group('DeviceIdentity', () {
    test('given_valid_mac_and_stableId_when_created_then_stores_both', () {
      final identity = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(identity.stableId, '550e8400-e29b-41d4-a716-446655440000');
      expect(identity.mac, 'AA:BB:CC:DD:EE:FF');
    });

    test('given_two_identities_with_same_stableId_when_compared_then_equal', () {
      final a = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      final b = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('given_identity_when_toString_then_shows_stableId_and_mac', () {
      final identity = DeviceIdentity(
        stableId: 'abc-123',
        mac: 'AA:BB',
      );
      expect(identity.toString(), contains('abc-123'));
      expect(identity.toString(), contains('AA:BB'));
    });
  });
}
