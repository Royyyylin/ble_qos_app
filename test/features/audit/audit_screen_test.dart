import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/data/database.dart';
import 'package:ble_qos_app/core/providers/database_provider.dart';
import 'package:ble_qos_app/features/audit/audit_screen.dart';

void main() {
  group('AuditScreen', () {
    testWidgets('renders with Audit Log title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditEntriesProvider
                .overrideWith((ref) => Stream.value(<AuditLogData>[])),
          ],
          child: const MaterialApp(home: AuditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Audit Log'), findsOneWidget);
    });

    testWidgets('shows role filter dropdown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditEntriesProvider
                .overrideWith((ref) => Stream.value(<AuditLogData>[])),
          ],
          child: const MaterialApp(home: AuditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('shows empty state message when no entries', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditEntriesProvider
                .overrideWith((ref) => Stream.value(<AuditLogData>[])),
          ],
          child: const MaterialApp(home: AuditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No audit entries'), findsOneWidget);
    });

    testWidgets('shows export CSV button stub', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditEntriesProvider
                .overrideWith((ref) => Stream.value(<AuditLogData>[])),
          ],
          child: const MaterialApp(home: AuditScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });
}
