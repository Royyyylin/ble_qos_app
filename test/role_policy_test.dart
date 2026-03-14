import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/domain/role_policy.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';

void main() {
  group('RolePolicy', () {
    test('patrol cannot write anything', () {
      expect(RolePolicy.canWrite(AppRole.patrol, GattUuids.ctrl), false);
      expect(RolePolicy.canWrite(AppRole.patrol, GattUuids.role), false);
      expect(RolePolicy.canWrite(AppRole.patrol, GattUuids.mode), false);
      expect(RolePolicy.canWrite(AppRole.patrol, GattUuids.gwCfg), false);
    });

    test('installer can write ROLE and CMD only', () {
      expect(RolePolicy.canWrite(AppRole.installer, GattUuids.role), true);
      expect(RolePolicy.canWrite(AppRole.installer, GattUuids.cmd), true);
      expect(RolePolicy.canWrite(AppRole.installer, GattUuids.ctrl), false);
      expect(RolePolicy.canWrite(AppRole.installer, GattUuids.mode), false);
      expect(RolePolicy.canWrite(AppRole.installer, GattUuids.gwCfg), false);
    });

    test('engineer can write all writable characteristics', () {
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.ctrl), true);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.mode), true);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.gwCfg), true);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.role), true);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.cmd), true);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.ping), true);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.engUnlock), true);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.engPinSet), true);
    });

    test('no role can write STATUS (read-only characteristic)', () {
      expect(RolePolicy.canWrite(AppRole.patrol, GattUuids.status), false);
      expect(RolePolicy.canWrite(AppRole.installer, GattUuids.status), false);
      expect(RolePolicy.canWrite(AppRole.engineer, GattUuids.status), false);
    });
  });
}
