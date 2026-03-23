import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';

void main() {
  group('DeviceStatus', () {
    test('has online, stale, offline values', () {
      expect(DeviceStatus.values, containsAll([
        DeviceStatus.online,
        DeviceStatus.stale,
        DeviceStatus.offline,
      ]));
    });
  });

  group('ScannedDevice', () {
    test('stores smoothedRssi field', () {
      final d = ScannedDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'GW-Test',
        rssi: -60,
        smoothedRssi: -62.5,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
      );
      expect(d.smoothedRssi, -62.5);
    });

    test('stores DeviceStatus field', () {
      final d = ScannedDevice(
        id: 'AA:BB',
        name: 'ED-1',
        rssi: -70,
        smoothedRssi: -70.0,
        status: DeviceStatus.stale,
        lastSeen: DateTime(2026, 1, 1),
      );
      expect(d.status, DeviceStatus.stale);
    });

    test('given ScannedDevice with GW ManufacturerData when accessed then mfgData is present', () {
      final mfg = ManufacturerData(
        protocolVersion: 1,
        role: ManufacturerData.roleGateway,
        networkId: 1,
        edCount: 3,
        haRole: 1,
      );
      final d = ScannedDevice(
        id: 'AA:BB',
        name: 'GW-1',
        rssi: -55,
        smoothedRssi: -55.0,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
        mfgData: mfg,
      );
      expect(d.mfgData, isNotNull);
      expect(d.mfgData!.isGateway, isTrue);
    });

    test('stores optional alias field', () {
      final d = ScannedDevice(
        id: 'AA:BB',
        name: 'GW-1',
        rssi: -55,
        smoothedRssi: -55.0,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
        alias: 'My Gateway',
      );
      expect(d.alias, 'My Gateway');
    });

    test('displayName returns alias when set', () {
      final d = ScannedDevice(
        id: 'AA:BB',
        name: 'GW-1',
        rssi: -55,
        smoothedRssi: -55.0,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
        alias: 'My GW',
      );
      expect(d.displayName, 'My GW');
    });

    test('displayName returns name when alias is null', () {
      final d = ScannedDevice(
        id: 'AA:BB',
        name: 'GW-1',
        rssi: -55,
        smoothedRssi: -55.0,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
      );
      expect(d.displayName, 'GW-1');
    });

    test('given_scannedDevice_with_mac_when_accessed_then_returns_mac', () {
      final d = ScannedDevice(
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'GW-Test',
        rssi: -60,
        smoothedRssi: -62.5,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(d.mac, 'AA:BB:CC:DD:EE:FF');
      expect(d.id, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('given_scannedDevice_without_mac_when_accessed_then_mac_is_null', () {
      final d = ScannedDevice(
        id: 'some-id',
        name: 'Test',
        rssi: -60,
        smoothedRssi: -60.0,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
      );
      expect(d.mac, isNull);
    });
  });

  group('BleConnectionState', () {
    test('given_BleConnectionState_when_values_accessed_then_includes_error_state', () {
      expect(BleConnectionState.values, contains(BleConnectionState.error));
    });

    test('given_BleConnectionState_when_values_accessed_then_has_five_states', () {
      expect(BleConnectionState.values.length, 5);
      expect(BleConnectionState.values, containsAll([
        BleConnectionState.disconnected,
        BleConnectionState.connecting,
        BleConnectionState.handshaking,
        BleConnectionState.connected,
        BleConnectionState.error,
      ]));
    });
  });

  group('EMA calculation', () {
    test('emaRssi with alpha=0.3 computes correctly', () {
      // smoothed = 0.3 * new + 0.7 * prev
      final result = emaRssi(-60, -70.0, alpha: 0.3);
      expect(result, closeTo(-67.0, 0.01)); // 0.3*-60 + 0.7*-70 = -18 + -49 = -67
    });

    test('emaRssi first reading (no previous)', () {
      final result = emaRssi(-60, null, alpha: 0.3);
      expect(result, -60.0);
    });
  });

  group('DeviceStatus from timing', () {
    test('online when lastSeen < 30s ago', () {
      final now = DateTime(2026, 1, 1, 0, 0, 15);
      final lastSeen = DateTime(2026, 1, 1, 0, 0, 0);
      expect(deviceStatusFromLastSeen(lastSeen, now: now), DeviceStatus.online);
    });

    test('stale when lastSeen 30-120s ago', () {
      final now = DateTime(2026, 1, 1, 0, 0, 45);
      final lastSeen = DateTime(2026, 1, 1, 0, 0, 0);
      expect(deviceStatusFromLastSeen(lastSeen, now: now), DeviceStatus.stale);
    });

    test('offline when lastSeen > 120s ago', () {
      final now = DateTime(2026, 1, 1, 0, 2, 5);
      final lastSeen = DateTime(2026, 1, 1, 0, 0, 0);
      expect(deviceStatusFromLastSeen(lastSeen, now: now), DeviceStatus.offline);
    });
  });
}
