// test/core/capability/capability_negotiator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';


void main() {
  group('CapabilityNegotiator', () {
    test('negotiate returns enabled tabs for compatible capabilities', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 1),
        const Capability(id: 'ha_runtime', version: 1),
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.enabledTabs, containsAll(['Dashboard', 'HA']));
      expect(result.incompatible, isEmpty);
      expect(result.unknown, isEmpty);
    });

    test('negotiate marks incompatible version', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 0), // too old
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.enabledTabs, isEmpty);
      expect(result.incompatible, hasLength(1));
    });

    test('negotiate ignores unknown capabilities', () {
      final caps = [
        const Capability(id: 'pressure_sensor', version: 1),
        const Capability(id: 'qos_monitor', version: 1),
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.enabledTabs, contains('Dashboard'));
      expect(result.unknown, contains('pressure_sensor'));
    });
  });
}
