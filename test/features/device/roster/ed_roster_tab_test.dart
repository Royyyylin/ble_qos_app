import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/ed_roster_provider.dart';
import 'package:ble_qos_app/features/device/roster/ed_roster_tab.dart';

const _connectedEdListEntry = EdListEntry(
  edIndex: 0, addrType: 1, address: 'ED:01', connected: true,
);

ScannedDevice _makeEd(String id, String name) => ScannedDevice(
      id: id,
      name: name,
      rssi: -55,
      smoothedRssi: -55.0,
      status: DeviceStatus.online,
      lastSeen: DateTime.now(),
      mfgData: const ManufacturerData(
        protocolVersion: 1,
        role: ManufacturerData.roleEndDevice,
        networkId: 0,
      ),
    );

void main() {
  group('EdRosterTab', () {
    testWidgets('given_empty_roster_when_rendered_then_shows_empty_state',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            edRosterProvider.overrideWithValue(const []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );

      expect(find.text('No End Devices found in this network'), findsOneWidget);
    });

    testWidgets(
        'given_ed_connected_to_gw_when_rendered_then_shows_disconnect_button',
        (tester) async {
      final roster = [
        EdRosterEntry(
          device: _makeEd('ED:01', 'ED-Alpha'),
          gwStatus: const QosStatus(edIndex: 0, zone: 0, profile: 1),
          edListEntry: _connectedEdListEntry,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            edRosterProvider.overrideWithValue(roster),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );

      expect(find.text('ED-Alpha'), findsOneWidget);
      expect(find.text('Disconnect'), findsOneWidget);
      expect(find.textContaining('NEAR'), findsOneWidget);
    });

    testWidgets(
        'given_ed_not_connected_when_rendered_then_shows_connect_button',
        (tester) async {
      final roster = [
        EdRosterEntry(
          device: _makeEd('ED:02', 'ED-Beta'),
          gwStatus: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            edRosterProvider.overrideWithValue(roster),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );

      expect(find.text('ED-Beta'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Not connected to GW'), findsOneWidget);
    });

    testWidgets(
        'given_multiple_eds_when_rendered_then_shows_correct_buttons',
        (tester) async {
      final roster = [
        EdRosterEntry(
          device: _makeEd('ED:01', 'ED-Alpha'),
          gwStatus: const QosStatus(edIndex: 0, zone: 2, profile: 0),
          edListEntry: _connectedEdListEntry,
        ),
        EdRosterEntry(
          device: _makeEd('ED:02', 'ED-Beta'),
          gwStatus: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            edRosterProvider.overrideWithValue(roster),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );

      expect(find.text('ED-Alpha'), findsOneWidget);
      expect(find.text('ED-Beta'), findsOneWidget);
      expect(find.text('Disconnect'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });
  });
}
