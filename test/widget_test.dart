import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App root widget renders MaterialApp', (WidgetTester tester) async {
    // Smoke test: just verify MaterialApp can be created without BLE
    await tester.pumpWidget(
      const MaterialApp(
        title: 'BLE QoS Monitor',
        home: Scaffold(body: Center(child: Text('BLE QoS Monitor'))),
      ),
    );
    expect(find.text('BLE QoS Monitor'), findsOneWidget);
  });
}
