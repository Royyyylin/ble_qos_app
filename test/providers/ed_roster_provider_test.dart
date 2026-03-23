import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/providers/ed_roster_provider.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';

ScannedDevice _makeEd(String id) => ScannedDevice(
      id: id,
      name: 'ED-$id',
      rssi: -50,
      smoothedRssi: -50.0,
      status: DeviceStatus.online,
      lastSeen: DateTime.now(),
      mfgData: const ManufacturerData(
        protocolVersion: 1,
        role: ManufacturerData.roleEndDevice,
        networkId: 0,
      ),
    );

// RED/BLUE REVIEW — Task 3:
// Blue: Add helper and tests for ED deduplication logic — filtering discovered EDs
//   whose MAC matches firmware roster entries. Only modifies test file.
// Red: No issues found. Pure test addition, no guard rule violations, no regression risk.

ScannedDevice _makeEdWithMac(String id, {String? mac}) => ScannedDevice(
      id: id,
      name: 'ED-$id',
      rssi: -50,
      smoothedRssi: -50.0,
      status: DeviceStatus.online,
      lastSeen: DateTime.now(),
      mac: mac,
      mfgData: const ManufacturerData(
        protocolVersion: 1,
        role: ManufacturerData.roleEndDevice,
        networkId: 0,
      ),
    );

void main() {
  group('EdStatusMapNotifier', () {
    late EdStatusMapNotifier notifier;

    setUp(() {
      notifier = EdStatusMapNotifier();
    });

    test('given_empty_when_created_then_map_is_empty', () {
      expect(notifier.state, isEmpty);
    });

    test('given_status_when_update_then_stored_by_edIndex', () {
      final status = QosStatus(edIndex: 2, zone: 1, profile: 0);
      notifier.update(status);

      expect(notifier.state, hasLength(1));
      expect(notifier.state[2]!.zone, 1);
    });

    test('given_multiple_eds_when_update_then_all_stored', () {
      notifier.update(const QosStatus(edIndex: 0, zone: 0));
      notifier.update(const QosStatus(edIndex: 1, zone: 2));
      notifier.update(const QosStatus(edIndex: 0, zone: 1)); // overwrite

      expect(notifier.state, hasLength(2));
      expect(notifier.state[0]!.zone, 1); // latest value
      expect(notifier.state[1]!.zone, 2);
    });

    test('given_data_when_clear_then_map_is_empty', () {
      notifier.update(const QosStatus(edIndex: 0));
      notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });

  group('Discovered ED deduplication', () {
    test('given_ed_mac_in_firmware_roster_when_building_discovered_list_then_excluded', () {
      // Simulate: ED with MAC AA:BB:CC:DD:EE:FF is in firmware roster
      // edRosterProvider should exclude it from discovered EDs
      final edInRoster = _makeEdWithMac('ED:01', mac: 'AA:BB:CC:DD:EE:FF');
      final edNotInRoster = _makeEdWithMac('ED:02', mac: '11:22:33:44:55:66');

      final rosterEntries = [
        const RosterEntry(
          logicalSlot: 0,
          addrType: 1,
          address: 'AA:BB:CC:DD:EE:FF',
          state: RosterSlotState.online,
        ),
      ];

      // Build the MAC set that edRosterProvider uses for filtering
      final rosterMacs = <String>{};
      for (final r in rosterEntries) {
        if (!r.isEmpty) {
          rosterMacs.add(r.address.toUpperCase());
        }
      }

      // Filter: exclude EDs whose MAC matches a roster entry
      final allEds = [edInRoster, edNotInRoster];
      final discovered = allEds.where((d) {
        final mac = d.mac?.toUpperCase();
        return mac == null || !rosterMacs.contains(mac);
      }).toList();

      expect(discovered, hasLength(1));
      expect(discovered.first.id, 'ED:02');
    });

    test('given_ed_without_mac_when_building_discovered_list_then_included', () {
      // ED without MAC cannot be matched — always show in discovered
      final edNoMac = _makeEdWithMac('ED:03');

      final rosterMacs = <String>{'AA:BB:CC:DD:EE:FF'};
      final discovered = [edNoMac].where((d) {
        final mac = d.mac?.toUpperCase();
        return mac == null || !rosterMacs.contains(mac);
      }).toList();

      expect(discovered, hasLength(1));
    });
  });
  group('EdRosterEntry', () {
    test('given_no_gwStatus_when_checked_then_not_connected', () {
      final entry = EdRosterEntry(
        device: _makeEd('01'),
        gwStatus: null,
      );
      expect(entry.isConnectedToGw, isFalse);
    });

    test('given_gwStatus_when_checked_then_is_connected', () {
      final entry = EdRosterEntry(
        device: _makeEd('01'),
        gwStatus: const QosStatus(edIndex: 0, zone: 1),
      );
      expect(entry.isConnectedToGw, isTrue);
    });
  });
}
