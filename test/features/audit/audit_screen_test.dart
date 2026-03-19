import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/features/audit/audit_screen.dart';

void main() {
  group('AuditScreen', () {
    testWidgets('renders with Audit Log title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Audit Log'), findsOneWidget);
    });

    testWidgets('shows role filter dropdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('shows empty state message when no entries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No audit entries'), findsOneWidget);
    });

    testWidgets('shows export CSV button stub', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });
}
