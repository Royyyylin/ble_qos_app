import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/auth/auth_session.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/features/device/control/control_tab.dart';

void main() {
  Widget buildTestWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(body: ControlTab(deviceId: 'test-device')),
      ),
    );
  }

  testWidgets(
    'given normal role when Write CTRL tapped then shows permission denied snackbar',
    (tester) async {
      final session = AuthSession(); // defaults to normal role
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          authSessionProvider.overrideWithValue(session),
        ],
      ));

      await tester.tap(find.text('Write CTRL'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Permission denied'), findsOneWidget);
    },
  );

  testWidgets(
    'given maintenance role when Write CTRL tapped then does not show permission denied',
    (tester) async {
      final session = AuthSession();
      session.elevate(AuthRole.maintenance);

      // Provide a BleConnector that won't cause disposal issues in test
      final connector = BleConnector();

      await tester.pumpWidget(buildTestWidget(
        overrides: [
          authSessionProvider.overrideWithValue(session),
          bleConnectorProvider.overrideWithValue(connector),
        ],
      ));

      // Tapping Write CTRL with maintenance role should not show permission denied
      // (it may show CTRL write failed since no real BLE connection exists in test)
      await tester.tap(find.text('Write CTRL'));
      await tester.pumpAndSettle();

      // Should NOT show permission denied
      expect(find.textContaining('Permission denied'), findsNothing);

      // Clean up timers from AuthSession.elevate before test framework checks
      session.dispose();
    },
  );
}
