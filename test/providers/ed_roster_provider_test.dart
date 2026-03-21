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

  group('EdRosterEntry', () {
    test('given_no_edListEntry_when_checked_then_not_connected', () {
      final entry = EdRosterEntry(
        device: _makeEd('01'),
        gwStatus: null,
        edListEntry: null,
      );
      expect(entry.isConnectedToGw, isFalse);
    });

    test('given_edListEntry_when_checked_then_is_connected', () {
      final entry = EdRosterEntry(
        device: _makeEd('01'),
        gwStatus: const QosStatus(edIndex: 0, zone: 1),
        edListEntry: const EdListEntry(
          edIndex: 0, addrType: 1, address: 'AA:BB:CC:DD:EE:01', connected: true,
        ),
      );
      expect(entry.isConnectedToGw, isTrue);
    });
  });
}
