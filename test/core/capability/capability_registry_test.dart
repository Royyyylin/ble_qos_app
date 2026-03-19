import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_registry.dart';

void main() {
  group('CapabilityRegistry', () {
    test('has handler for qos_monitor', () {
      expect(CapabilityRegistry.hasHandler('qos_monitor'), isTrue);
    });

    test('has handler for ha_runtime', () {
      expect(CapabilityRegistry.hasHandler('ha_runtime'), isTrue);
    });

    test('returns null for unknown capability', () {
      expect(CapabilityRegistry.getHandler('pressure_sensor'), isNull);
    });

    test('isCompatible returns true for matching version', () {
      expect(
        CapabilityRegistry.isCompatible(const Capability(id: 'qos_monitor', version: 1)),
        isTrue,
      );
    });

    test('isCompatible returns false for too-old version', () {
      expect(
        CapabilityRegistry.isCompatible(const Capability(id: 'qos_monitor', version: 0)),
        isFalse,
      );
    });

    test('fallback capabilities for gateway role', () {
      final caps = CapabilityRegistry.fallbackForRole(0x02); // ROLE_GATEWAY
      expect(caps.map((c) => c.id), containsAll(['qos_monitor', 'ed_roster', 'ha_runtime']));
    });

    test('fallback capabilities for end_device role', () {
      final caps = CapabilityRegistry.fallbackForRole(0x01); // ROLE_END_DEVICE
      expect(caps.map((c) => c.id), contains('qos_monitor'));
    });
  });
}
