import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/ed_roster_provider.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/features/device/roster/ed_roster_tab.dart';

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

/// Override rosterListProvider with empty list (no GATT connection in tests).
Override _emptyRosterList() =>
    rosterListProvider.overrideWith((ref) => Future.value(const <RosterEntry>[]));

void main() {
  group('EdRosterTab', () {
    testWidgets('given_empty_roster_when_rendered_then_shows_empty_state',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            edRosterProvider.overrideWithValue(const []),
            _emptyRosterList(),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No End Devices found in this network'), findsOneWidget);
    });

    testWidgets(
        'given_eds_with_status_when_rendered_then_shows_online_badge',
        (tester) async {
      final roster = [
        EdRosterEntry(
          device: _makeEd('ED:01', 'ED-Alpha'),
          gwStatus: const QosStatus(edIndex: 0, zone: 0, profile: 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            edRosterProvider.overrideWithValue(roster),
            _emptyRosterList(),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ED-Alpha'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.textContaining('NEAR'), findsOneWidget);
      expect(find.textContaining('BALANCED'), findsOneWidget);
    });

    testWidgets(
        'given_ed_without_status_when_rendered_then_shows_offline',
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
            _emptyRosterList(),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ED-Beta'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Not connected to GW'), findsOneWidget);
    });

    testWidgets(
        'given_multiple_eds_when_rendered_then_shows_all',
        (tester) async {
      final roster = [
        EdRosterEntry(
          device: _makeEd('ED:01', 'ED-Alpha'),
          gwStatus: const QosStatus(edIndex: 0, zone: 2, profile: 0),
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
            _emptyRosterList(),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ED-Alpha'), findsOneWidget);
      expect(find.text('ED-Beta'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets(
        'given_firmware_roster_entries_when_rendered_then_shows_slot_info',
        (tester) async {
      final rosterEntries = [
        const RosterEntry(
          logicalSlot: 0,
          addrType: 1,
          address: 'AA:BB:CC:DD:EE:FF',
          state: RosterSlotState.online,
        ),
        const RosterEntry(
          logicalSlot: 1,
          addrType: 1,
          address: '11:22:33:44:55:66',
          state: RosterSlotState.registered,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            edRosterProvider.overrideWithValue(const []),
            rosterListProvider.overrideWith((ref) => Future.value(rosterEntries)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EdRosterTab(deviceId: 'GW-01')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AA:BB:CC:DD:EE:FF'), findsOneWidget);
      expect(find.text('11:22:33:44:55:66'), findsOneWidget);
      expect(find.textContaining('Slot 0'), findsOneWidget);
      expect(find.textContaining('Slot 1'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
    });
  });
}
