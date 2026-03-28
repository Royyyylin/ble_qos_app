import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../telemetry/device_state.dart';
import '../telemetry/telemetry_snapshot.dart';
import '../telemetry/telemetry_value_state.dart';
import 'telemetry_state_provider.dart';

/// Roster item for UI display — combines EdDeviceState with presentation helpers.
class RosterItemState {
  final EdDeviceState device;

  const RosterItemState(this.device);

  String get edId => device.edId;
  String get displayName => device.displayName;
  AssignmentState get assignmentState => device.assignmentState;
  bool get isOnline => device.assignmentState == AssignmentState.active;
  bool get isSparse => device.isSparseProfile;

  /// RSSI display value — respects sparse/unknown/stale states.
  String get rssiDisplay {
    final m = device.telemetry?.rssi;
    if (m == null) return '--';
    return switch (m.state) {
      TelemetryValueState.present => '${m.value}',
      TelemetryValueState.stale => '${m.value}',
      TelemetryValueState.sparse => '--',
      TelemetryValueState.unknown => '--',
      TelemetryValueState.notSynced => '--',
    };
  }

  String get pdrDisplay => _fmtMetric(device.telemetry?.pdr);
  String get latencyDisplay => _fmtMetric(device.telemetry?.latency);
  String get jitterDisplay => _fmtMetric(device.telemetry?.jitter);
  String get phyDisplay => _fmtMetric(device.telemetry?.phy);
  String get txPowerDisplay => _fmtMetric(device.telemetry?.txPower);

  String get throughputDisplay {
    final m = device.telemetry?.throughput;
    if (m == null) return '--';
    if (m.state == TelemetryValueState.present && m.value == 0) return 'N/A';
    return _fmtMetric(m);
  }

  static String _fmtMetric<T extends num>(MetricValue<T>? m) {
    if (m == null) return '--';
    return switch (m.state) {
      TelemetryValueState.present => '${m.value}',
      TelemetryValueState.stale => '${m.value}',
      _ => '--',
    };
  }
}

/// All ED roster items derived from [edDeviceStateMapProvider].
final rosterItemsProvider = Provider<List<RosterItemState>>((ref) {
  final deviceMap = ref.watch(edDeviceStateMapProvider);
  final items = deviceMap.values.map((d) => RosterItemState(d)).toList();
  // Online first, then by edId
  items.sort((a, b) {
    if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
    return a.edId.compareTo(b.edId);
  });
  return items;
});

/// Single ED detail state by edId.
final edDetailProvider = Provider.family<EdDeviceState?, String>((ref, edId) {
  final deviceMap = ref.watch(edDeviceStateMapProvider);
  return deviceMap[edId];
});

/// Single ED telemetry snapshot by edId.
final edTelemetryProvider = Provider.family<TelemetrySnapshot?, String>((ref, edId) {
  final snapshots = ref.watch(telemetrySnapshotMapProvider);
  return snapshots[edId];
});
