// lib/core/capability/capability_negotiator.dart
import 'capability_model.dart';
import 'capability_registry.dart';

/// Result of capability negotiation — spec §5.3.
class NegotiationResult {
  final List<String> enabledTabs;
  final List<Capability> incompatible;
  final List<String> unknown;

  const NegotiationResult({
    required this.enabledTabs,
    required this.incompatible,
    required this.unknown,
  });
}

/// Negotiate device capabilities against local registry — spec §5.3.
class CapabilityNegotiator {
  CapabilityNegotiator._();

  static NegotiationResult negotiate(List<Capability> deviceCaps) {
    final enabledTabs = <String>[];
    final incompatible = <Capability>[];
    final unknown = <String>[];

    for (final cap in deviceCaps) {
      final handler = CapabilityRegistry.getHandler(cap.id);
      if (handler == null) {
        unknown.add(cap.id);
      } else if (cap.version < handler.minVersion) {
        incompatible.add(cap);
      } else {
        enabledTabs.add(handler.tabLabel);
      }
    }

    return NegotiationResult(
      enabledTabs: enabledTabs,
      incompatible: incompatible,
      unknown: unknown,
    );
  }
}
