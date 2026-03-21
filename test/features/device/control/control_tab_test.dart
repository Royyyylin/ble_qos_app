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
    'given_control_tab_when_rendered_then_shows_profile_selector',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          authSessionProvider.overrideWithValue(AuthSession()),
        ],
      ));

      expect(find.text('FAST'), findsOneWidget);
      expect(find.text('BALANCED'), findsOneWidget);
      expect(find.text('ROBUST'), findsOneWidget);
      expect(find.text('Apply Profile'), findsOneWidget);
    },
  );

  testWidgets(
    'given normal role when Apply Profile tapped then shows permission denied',
    (tester) async {
      final session = AuthSession();
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          authSessionProvider.overrideWithValue(session),
        ],
      ));

      await tester.tap(find.text('Apply Profile'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Permission denied'), findsOneWidget);
    },
  );

  testWidgets(
    'given maintenance role when Apply Profile tapped then does not show permission denied',
    (tester) async {
      final session = AuthSession();
      session.elevate(AuthRole.maintenance);
      final connector = BleConnector();

      await tester.pumpWidget(buildTestWidget(
        overrides: [
          authSessionProvider.overrideWithValue(session),
          bleConnectorProvider.overrideWithValue(connector),
        ],
      ));

      await tester.tap(find.text('Apply Profile'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Permission denied'), findsNothing);
      session.dispose();
    },
  );
}
