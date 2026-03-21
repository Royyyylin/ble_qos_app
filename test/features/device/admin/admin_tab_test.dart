import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/auth/auth_session.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/features/device/admin/admin_tab.dart';

void main() {
  group('AdminTab', () {
    testWidgets('given normal auth when rendered then shows ENG_UNLOCK enabled and CMD disabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Engineer Admin'), findsOneWidget);
      expect(find.text('ENG_UNLOCK'), findsOneWidget);
      expect(find.text('CMD Reboot'), findsOneWidget);
      expect(find.text('MODE / ROLE'), findsOneWidget);
    });

    testWidgets('given normal auth when ENG_UNLOCK tapped then shows PIN dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ENG_UNLOCK'));
      await tester.pumpAndSettle();

      expect(find.text('Engineer Unlock'), findsOneWidget);
      expect(find.text('Engineer PIN'), findsOneWidget);
    });

    testWidgets('given engineer auth when rendered then shows ENG_UNLOCK as active', (tester) async {
      final session = AuthSession();
      session.elevate(AuthRole.engineer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWithValue(session),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Engineer mode active'), findsOneWidget);
      session.dispose();
    });

    testWidgets('given engineer auth when CMD Reboot tapped then shows confirmation dialog', (tester) async {
      final session = AuthSession();
      session.elevate(AuthRole.engineer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWithValue(session),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CMD Reboot'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Reboot'), findsOneWidget);
      expect(find.textContaining('reboot the device'), findsOneWidget);
      session.dispose();
    });
  });
}
