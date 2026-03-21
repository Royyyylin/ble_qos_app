import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/providers/device_provider.dart';
import 'package:ble_qos_app/features/device/device_screen.dart';

/// Override bleConnectionStateProvider to return connected state for tests
final _connectedOverride = bleConnectionStateProvider.overrideWith(
  (ref) => Stream.value(BleConnectionState.connected),
);

/// Create a connectedDeviceProvider override with a specific role.
Override _deviceOverride(int role) {
  return connectedDeviceProvider.overrideWith((ref) {
    final notifier = ConnectedDeviceNotifier();
    // Simulate setting state directly via connect with a fake ScannedDevice
    notifier.connect(ScannedDevice(
      id: 'TEST',
      name: 'TEST',
      rssi: -50,
      smoothedRssi: -50,
      status: DeviceStatus.online,
      lastSeen: DateTime.now(),
      mfgData: ManufacturerData(
        protocolVersion: 1,
        role: role,
        networkId: 0,
      ),
    ));
    return notifier;
  });
}

void main() {
  group('DeviceScreen', () {
    testWidgets('renders with deviceId in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _connectedOverride,
            _deviceOverride(ManufacturerData.roleGateway),
          ],
          child: const MaterialApp(
            home: DeviceScreen(deviceId: 'AA:BB:CC'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AA:BB:CC'), findsOneWidget);
    });

    testWidgets('shows Dashboard content for ED role (qos_monitor only)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _connectedOverride,
            _deviceOverride(ManufacturerData.roleEndDevice),
          ],
          child: const MaterialApp(
            home: DeviceScreen(deviceId: 'TEST-01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ED has only qos_monitor → single tab → no TabBar, just DashboardTab
      expect(find.text('Telemetry'), findsOneWidget);
    });

    testWidgets('shows HA tab for GW role (has ha_runtime capability)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _connectedOverride,
            _deviceOverride(ManufacturerData.roleGateway),
          ],
          child: const MaterialApp(
            home: DeviceScreen(deviceId: 'TEST-02'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('HA'), findsOneWidget);
    });

    testWidgets('shows Control and Admin tabs when flags set', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _connectedOverride,
            _deviceOverride(ManufacturerData.roleGateway),
          ],
          child: const MaterialApp(
            home: DeviceScreen(
              deviceId: 'TEST-03',
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

    testWidgets('shows no capabilities message for unprovisioned device', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            _connectedOverride,
            _deviceOverride(ManufacturerData.roleUnprovisioned),
          ],
          child: const MaterialApp(
            home: DeviceScreen(deviceId: 'TEST-05'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No compatible capabilities'), findsOneWidget);
    });
  });
}
