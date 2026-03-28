import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gatt/gatt_structs.dart';
import '../telemetry/device_state.dart';
import '../telemetry/telemetry_adapter.dart';
import '../telemetry/telemetry_snapshot.dart';
import '../telemetry/telemetry_value_state.dart';
import 'device_provider.dart';
import 'ed_roster_provider.dart';
import 'identity_provider.dart';
import 'metrics_provider.dart';
import 'telemetry_state_provider.dart';

/// Bridge provider that converts existing GATT data streams into
/// profile-aware [TelemetrySnapshot] and [EdDeviceState].
///
/// This is the single integration point between old GATT providers
/// and new telemetry state model. Minimal invasive — old providers
/// continue to work, this layer adds the new state on top.
final telemetryBridgeProvider = Provider.autoDispose<void>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final identityService = ref.read(identityServiceProvider);

  // 1. STATUS polling (13B) → P1 TelemetrySnapshot
  ref.listen<AsyncValue<QosStatus>>(statusStreamProvider, (prev, next) {
    final status = next.valueOrNull;
    if (status == null) return;

    final edId = 'ed:${device.mac ?? device.id}';
    final snapshot = TelemetryAdapter.fromQosStatus(edId, status);
    _updateSnapshot(ref, edId, snapshot);
  });

  // 2. Indexed STATUS notify (4B) → P0 sparse TelemetrySnapshot per-ED
  ref.listen<Map<int, QosStatus>>(edStatusMapProvider, (prev, next) {
    final rosterAsync = ref.read(rosterListProvider);
    final rosterEntries = rosterAsync.valueOrNull ?? const [];

    for (final entry in next.entries) {
      final edIdx = entry.key;
      final indexed = entry.value;

      // Map ed_idx → MAC → ed_id via ROSTER_LIST
      final rosterEntry = rosterEntries
          .where((r) => r.logicalSlot == edIdx && !r.isEmpty)
          .firstOrNull;
      if (rosterEntry == null) continue;

      final edMac = rosterEntry.address.toUpperCase();
      final edId = 'ed:$edMac';

      final snapshot = TelemetryAdapter.fromIndexedStatus(edId, indexed);
      _updateSnapshot(ref, edId, snapshot);
    }
  });

  // 3. METRICS_V2 notify (20B) → P1 TelemetrySnapshot
  ref.listen<AsyncValue<QosMetricsV2>>(metricsStreamProvider, (prev, next) {
    final metrics = next.valueOrNull;
    if (metrics == null) return;

    final edId = 'ed:${device.mac ?? device.id}';
    final snapshot = TelemetryAdapter.fromMetricsV2(edId, metrics);
    _updateSnapshot(ref, edId, snapshot);
  });

  // 4. ROSTER_LIST → build EdDeviceState for each slot
  ref.listen<AsyncValue<List<RosterEntry>>>(rosterListProvider, (prev, next) {
    final entries = next.valueOrNull;
    if (entries == null) return;

    final connDevice = ref.read(connectedDeviceProvider);
    final gwMac = connDevice?.mac ?? connDevice?.id ?? '';
    final gwId = 'gw:${gwMac.toUpperCase()}';
    final snapshots = ref.read(telemetrySnapshotMapProvider);

    final deviceMap = <String, EdDeviceState>{};
    for (final r in entries) {
      if (r.isEmpty) continue;

      final edMac = r.address.toUpperCase();
      final edId = 'ed:$edMac';
      final snap = snapshots[edId];
      final alias = identityService.getAlias(
        identityService.resolveOrAssignSync(edMac),
      );

      deviceMap[edId] = EdDeviceState(
        edId: edId,
        edMac: edMac,
        activeGatewayId: gwId,
        assignmentState: r.isOnline ? AssignmentState.active : AssignmentState.pending,
        alias: alias,
        telemetry: snap ?? TelemetryAdapter.notConnected(edId),
        lastPayloadProfile: snap?.profile,
        isSparseProfile: snap?.profile == PayloadProfile.p0,
      );
    }

    ref.read(edDeviceStateMapProvider.notifier).state = deviceMap;
    debugPrint('[BRIDGE] EdDeviceState map updated: ${deviceMap.length} EDs');
  });
});

/// Merge incoming snapshot into existing map with stale-retention.
void _updateSnapshot(Ref ref, String edId, TelemetrySnapshot incoming) {
  final map = ref.read(telemetrySnapshotMapProvider);
  final existing = map[edId];
  final merged = existing != null
      ? TelemetryAdapter.merge(existing, incoming)
      : incoming;

  ref.read(telemetrySnapshotMapProvider.notifier).state = {
    ...map,
    edId: merged,
  };
}
