import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/widgets/connection_state_indicator.dart';

void main() {
  Widget buildTestWidget(BleConnectionState state) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [ConnectionStateIndicator(state: state)],
        ),
      ),
    );
  }

  group('ConnectionStateIndicator', () {
    testWidgets(
      'given_connecting_state_when_rendered_then_shows_progress_indicator',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.connecting));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'given_handshaking_state_when_rendered_then_shows_progress_indicator',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.handshaking));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'given_connected_state_when_rendered_then_shows_check_icon',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.connected));
        expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
      },
    );

    testWidgets(
      'given_error_state_when_rendered_then_shows_error_icon',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.error));
        expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
      },
    );

    testWidgets(
      'given_disconnected_state_when_rendered_then_shows_disabled_icon',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.disconnected));
        expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
      },
    );
  });
}
