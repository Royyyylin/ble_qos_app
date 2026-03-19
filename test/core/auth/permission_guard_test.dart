// test/core/auth/permission_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/auth/auth_session.dart';

void main() {
  group('PermissionGuard', () {
    test('normal user can read all', () {
      expect(PermissionGuard.canRead(AuthRole.normal, GattAction.status), isTrue);
      expect(PermissionGuard.canRead(AuthRole.normal, GattAction.metrics), isTrue);
    });

    test('normal user cannot write CTRL', () {
      expect(PermissionGuard.canWrite(AuthRole.normal, GattAction.ctrl), isFalse);
    });

    test('maintenance can write CTRL and GW_CFG', () {
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.ctrl), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.gwCfg), isTrue);
    });

    test('maintenance cannot write MODE or ROLE', () {
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.mode), isFalse);
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.role), isFalse);
    });

    test('engineer can write all writable', () {
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.ctrl), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.mode), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.role), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.engUnlock), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.engPinSet), isTrue);
    });

    test('maintenance CMD reboot requires confirmation', () {
      expect(PermissionGuard.requiresConfirmation(AuthRole.maintenance, GattAction.cmdReboot), isTrue);
      expect(PermissionGuard.requiresConfirmation(AuthRole.engineer, GattAction.cmdReboot), isFalse);
    });
  });
}
