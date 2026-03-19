import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/auth/auth_session.dart';

void main() {
  group('AuthSession', () {
    test('starts at Role-0 (normal)', () {
      final session = AuthSession();
      expect(session.currentRole, AuthRole.normal);
    });

    test('elevate to maintenance sets role', () {
      final session = AuthSession();
      session.elevate(AuthRole.maintenance);
      expect(session.currentRole, AuthRole.maintenance);
    });

    test('elevate to engineer sets role', () {
      final session = AuthSession();
      session.elevate(AuthRole.engineer);
      expect(session.currentRole, AuthRole.engineer);
    });

    test('demote returns to normal', () {
      final session = AuthSession();
      session.elevate(AuthRole.maintenance);
      session.demote();
      expect(session.currentRole, AuthRole.normal);
    });

    test('isElevated returns true for maintenance and engineer', () {
      final session = AuthSession();
      expect(session.isElevated, isFalse);
      session.elevate(AuthRole.maintenance);
      expect(session.isElevated, isTrue);
    });

    test('idle timeout config differs by role', () {
      expect(AuthRole.maintenance.idleTimeout, const Duration(minutes: 15));
      expect(AuthRole.engineer.idleTimeout, const Duration(minutes: 5));
    });

    test('absolute timeout config differs by role', () {
      expect(AuthRole.maintenance.absoluteTimeout, const Duration(hours: 8));
      expect(AuthRole.engineer.absoluteTimeout, const Duration(hours: 4));
    });
  });
}
