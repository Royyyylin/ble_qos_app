// lib/core/capability/capability_negotiator.dart
import 'capability_model.dart';
import 'capability_registry.dart';
import 'degradation_info.dart';

/// Result of capability negotiation — spec §5.3.
class NegotiationResult {
  final List<String> enabledTabs;
  final List<Capability> incompatible;
  final List<String> unknown;

  /// Degradation details for incompatible capabilities — used by UI badges.
  final List<DegradationInfo> degraded;

  const NegotiationResult({
    required this.enabledTabs,
    required this.incompatible,
    required this.unknown,
    this.degraded = const [],
  });

  /// True when all known capabilities are incompatible (show "limited mode" banner).
  bool get isLimitedMode =>
      enabledTabs.isEmpty && incompatible.isNotEmpty;
}

/// Negotiate device capabilities against local registry — spec §5.3.
class CapabilityNegotiator {
  CapabilityNegotiator._();

  static NegotiationResult negotiate(List<Capability> deviceCaps) {
    final enabledTabs = <String>[];
    final incompatible = <Capability>[];
    final unknown = <String>[];
    final degraded = <DegradationInfo>[];

    for (final cap in deviceCaps) {
      final handler = CapabilityRegistry.getHandler(cap.id);
      if (handler == null) {
        unknown.add(cap.id);
      } else if (cap.version < handler.minVersion) {
        incompatible.add(cap);
        degraded.add(DegradationInfo(
          capId: cap.id,
          deviceVersion: cap.version,
          requiredVersion: handler.minVersion,
          tabLabel: handler.tabLabel,
        ));
      } else {
        enabledTabs.add(handler.tabLabel);
      }
    }

    return NegotiationResult(
      enabledTabs: enabledTabs,
      incompatible: incompatible,
      unknown: unknown,
      degraded: degraded,
    );
  }
}
