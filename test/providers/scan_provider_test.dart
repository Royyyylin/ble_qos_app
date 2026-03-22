import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/providers/scan_provider.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';

ScannedDevice _makeDevice({
  required String id,
  required String name,
  int role = ManufacturerData.roleEndDevice,
  int networkId = 0,
}) {
  return ScannedDevice(
    id: id,
    name: name,
    rssi: -50,
    smoothedRssi: -50.0,
    status: DeviceStatus.online,
    lastSeen: DateTime.now(),
    mfgData: ManufacturerData(
      protocolVersion: 1,
      role: role,
      networkId: networkId,
    ),
  );
}

void main() {
  group('ScanResultsNotifier', () {
    late ScanResultsNotifier notifier;

    setUp(() {
      notifier = ScanResultsNotifier();
    });

    test('given_empty_when_created_then_state_is_empty', () {
      expect(notifier.state, isEmpty);
    });

    test('given_devices_when_update_then_state_contains_devices', () {
      final devices = [
        _makeDevice(id: 'AA:BB', name: 'ED-1'),
        _makeDevice(id: 'CC:DD', name: 'ED-2'),
      ];
      notifier.update(devices);
      expect(notifier.state, hasLength(2));
      expect(notifier.state[0].id, 'AA:BB');
    });

    test('given_devices_when_clear_then_state_is_empty', () {
      notifier.update([_makeDevice(id: 'AA:BB', name: 'ED-1')]);
      notifier.clear();
      expect(notifier.state, isEmpty);
    });

    test('given_mixed_devices_when_edsForNetwork_then_returns_only_matching_eds', () {
      final gw = _makeDevice(
        id: 'GW:01',
        name: 'GW-1',
        role: ManufacturerData.roleGateway,
        networkId: 0,
      );
      final ed1 = _makeDevice(id: 'ED:01', name: 'ED-1', networkId: 0);
      final ed2 = _makeDevice(id: 'ED:02', name: 'ED-2', networkId: 0);
      final edOther = _makeDevice(id: 'ED:03', name: 'ED-3', networkId: 1);

      notifier.update([gw, ed1, ed2, edOther]);
      final result = notifier.edsForNetwork(0);

      expect(result, hasLength(2));
      expect(result[0].id, 'ED:01');
      expect(result[1].id, 'ED:02');
    });

    test('given_no_eds_in_network_when_edsForNetwork_then_returns_empty', () {
      final gw = _makeDevice(
        id: 'GW:01',
        name: 'GW-1',
        role: ManufacturerData.roleGateway,
        networkId: 0,
      );
      notifier.update([gw]);
      expect(notifier.edsForNetwork(0), isEmpty);
    });
  });
}
