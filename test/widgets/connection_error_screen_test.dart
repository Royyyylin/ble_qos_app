import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/widgets/connection_error_screen.dart';

void main() {
  group('ConnectionErrorScreen', () {
    testWidgets(
      'given_error_message_when_rendered_then_shows_message_and_retry_button',
      (tester) async {
        bool retried = false;
        await tester.pumpWidget(MaterialApp(
          home: ConnectionErrorScreen(
            message: 'Connection lost',
            onRetry: () => retried = true,
          ),
        ));
        expect(find.text('Connection lost'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        expect(retried, isTrue);
      },
    );

    testWidgets(
      'given_error_screen_when_rendered_then_shows_error_icon',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: ConnectionErrorScreen(
            message: 'Failed',
            onRetry: () {},
          ),
        ));
        expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
      },
    );

    testWidgets(
      'given_error_screen_with_non_retryable_error_when_rendered_then_hides_retry',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ConnectionErrorScreen(
            message: 'Unsupported device',
            isRetryable: false,
          ),
        ));
        expect(find.text('Unsupported device'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      },
    );
  });
}
