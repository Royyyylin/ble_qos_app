import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ble_qos_app/main.dart';

void main() {
  testWidgets('BleQosApp renders with dark theme and GoRouter', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BleQosApp()));
    await tester.pumpAndSettle();

    // Verify the app renders with the Fleet Overview (scanner) screen
    expect(find.text('Fleet Overview'), findsOneWidget);
  });

  testWidgets('BleQosApp uses dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BleQosApp()));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.dark);
  });
}
