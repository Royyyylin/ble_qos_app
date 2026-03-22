import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/degradation_info.dart';

void main() {
  group('DegradationInfo', () {
    test('given_version_mismatch_when_created_then_stores_all_fields', () {
      final info = DegradationInfo(
        capId: 'qos_monitor',
        deviceVersion: 0,
        requiredVersion: 1,
        tabLabel: 'Dashboard',
      );
      expect(info.capId, 'qos_monitor');
      expect(info.deviceVersion, 0);
      expect(info.requiredVersion, 1);
      expect(info.tabLabel, 'Dashboard');
    });

    test('given_degradation_info_when_message_accessed_then_returns_human_readable', () {
      final info = DegradationInfo(
        capId: 'ha_runtime',
        deviceVersion: 0,
        requiredVersion: 1,
        tabLabel: 'HA',
      );
      expect(info.message, contains('v0'));
      expect(info.message, contains('v1'));
    });

    test('given_two_identical_infos_when_compared_then_equal', () {
      final a = DegradationInfo(
        capId: 'qos_monitor', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'Dashboard',
      );
      final b = DegradationInfo(
        capId: 'qos_monitor', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'Dashboard',
      );
      expect(a, equals(b));
    });
  });
}
