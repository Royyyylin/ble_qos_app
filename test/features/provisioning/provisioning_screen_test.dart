import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/features/provisioning/provisioning_screen.dart';

void main() {
  group('ProvisioningScreen', () {
    testWidgets('renders with device ID in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'AA:BB:CC:DD'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Provisioning'), findsOneWidget);
      expect(find.text('AA:BB:CC:DD'), findsOneWidget);
    });

    testWidgets('shows role selector with GW/ED/CC options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Role'), findsOneWidget);
      // DropdownButton should contain role options
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows network ID input field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-02'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Network ID'), findsOneWidget);
    });

    testWidgets('shows device name input field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-03'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Device Name'), findsOneWidget);
    });

    testWidgets('shows provision button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-04'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Write ROLE'), findsOneWidget);
    });

    testWidgets('shows reboot warning text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-05'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('reboot'), findsOneWidget);
    });

    testWidgets('given ProviderScope when rendered then shows Write ROLE button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'AA:BB:CC:DD'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'Write ROLE'), findsOneWidget);
    });
  });
}
