import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/features/device/device_screen.dart';

/// Override bleConnectionStateProvider to return connected state for tests
final _connectedOverrides = [
  bleConnectionStateProvider.overrideWith(
    (ref) => Stream.value(BleConnectionState.connected),
  ),
];

void main() {
  group('DeviceScreen', () {
    testWidgets('renders with deviceId in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _connectedOverrides,
          child: MaterialApp(
            home: DeviceScreen(
              deviceId: 'AA:BB:CC',
              capabilities: const [
                Capability(id: 'qos_monitor', version: 1),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AA:BB:CC'), findsOneWidget);
    });

    testWidgets('shows Dashboard content for qos_monitor capability', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _connectedOverrides,
          child: MaterialApp(
            home: DeviceScreen(
              deviceId: 'TEST-01',
              capabilities: const [
                Capability(id: 'qos_monitor', version: 1),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Single tab renders DashboardTab directly (no TabBar)
      expect(find.text('Telemetry'), findsOneWidget);
    });

    testWidgets('shows HA tab for ha_runtime capability', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _connectedOverrides,
          child: MaterialApp(
            home: DeviceScreen(
              deviceId: 'TEST-02',
              capabilities: const [
                Capability(id: 'qos_monitor', version: 1),
                Capability(id: 'ha_runtime', version: 1),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('HA'), findsOneWidget);
    });

    testWidgets('shows Control and Admin tabs when present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _connectedOverrides,
          child: MaterialApp(
            home: DeviceScreen(
              deviceId: 'TEST-03',
              capabilities: const [
                Capability(id: 'qos_monitor', version: 1),
                Capability(id: 'ha_runtime', version: 1),
              ],
              showControlTab: true,
              showAdminTab: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Control'), findsOneWidget);
      expect(find.text('HA'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('does not show tabs for incompatible capabilities', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _connectedOverrides,
          child: MaterialApp(
            home: DeviceScreen(
              deviceId: 'TEST-04',
              capabilities: const [
                Capability(id: 'qos_monitor', version: 0), // too old
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not show Dashboard for incompatible version
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('shows no tabs message when no compatible capabilities', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _connectedOverrides,
          child: MaterialApp(
            home: DeviceScreen(
              deviceId: 'TEST-05',
              capabilities: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No compatible capabilities'), findsOneWidget);
    });
  });
}
