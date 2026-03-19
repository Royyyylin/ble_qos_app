import 'capability_model.dart';

/// Handler metadata for a capability — spec §5.2.
class CapabilityHandler {
  final String tabLabel;
  final int minVersion;

  const CapabilityHandler({required this.tabLabel, required this.minVersion});
}

/// Capability registry — maps cap_id → handler + min version.
class CapabilityRegistry {
  CapabilityRegistry._();

  static const _handlers = <String, CapabilityHandler>{
    'qos_monitor':  CapabilityHandler(tabLabel: 'Dashboard', minVersion: 1),
    'ha_runtime':   CapabilityHandler(tabLabel: 'HA', minVersion: 1),
    'ed_roster':    CapabilityHandler(tabLabel: 'Roster', minVersion: 1),
    'central_sync': CapabilityHandler(tabLabel: 'Sync', minVersion: 1),
    'demo_traffic': CapabilityHandler(tabLabel: 'Demo', minVersion: 1),
  };

  static bool hasHandler(String capId) => _handlers.containsKey(capId);

  static CapabilityHandler? getHandler(String capId) => _handlers[capId];

  static bool isCompatible(Capability cap) {
    final handler = _handlers[cap.id];
    if (handler == null) return false;
    return cap.version >= handler.minVersion;
  }

  /// Fallback when Capability Characteristic is absent — spec §5.3.
  static List<Capability> fallbackForRole(int roleValue) {
    return switch (roleValue) {
      0x02 => const [  // ROLE_GATEWAY
        Capability(id: 'qos_monitor', version: 1),
        Capability(id: 'ed_roster', version: 1),
        Capability(id: 'ha_runtime', version: 1),
      ],
      0x01 => const [  // ROLE_END_DEVICE
        Capability(id: 'qos_monitor', version: 1),
      ],
      0x04 => const [  // ROLE_CC
        Capability(id: 'central_sync', version: 1),
        Capability(id: 'ha_runtime', version: 1),
      ],
      _ => const [],
    };
  }
}
