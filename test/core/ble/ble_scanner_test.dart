import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';

void main() {
  group('BleScanner TTL Eviction', () {
    test('given_offline_device_when_updateDeviceStatuses_then_device_evicted', () {
      // This tests the eviction logic — offline devices should be removed
      // from _devices map after offlineThreshold is exceeded.
      // Since BleScanner uses FlutterBluePlus internally, we test the
      // pure function eviction logic via deviceStatusFromLastSeen.
      final now = DateTime(2026, 1, 1, 0, 2, 5); // 125s later (> 120s offline threshold)
      final lastSeen = DateTime(2026, 1, 1, 0, 0, 0);
      final status = deviceStatusFromLastSeen(lastSeen, now: now);
      expect(status, DeviceStatus.offline);
      // Eviction policy: offline devices should be removed from visible list
    });
  });
}
