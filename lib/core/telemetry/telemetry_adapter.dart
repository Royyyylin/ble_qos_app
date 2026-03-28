import '../gatt/gatt_structs.dart';
import 'telemetry_snapshot.dart';
import 'telemetry_value_state.dart';

/// Converts firmware GATT structs into profile-aware [TelemetrySnapshot].
///
/// This adapter bridges the existing GATT wire format to the new
/// profile-aware model. It determines whether data represents a
/// P0 sparse or P1 complete payload and wraps values accordingly.
class TelemetryAdapter {
  TelemetryAdapter._();

  /// Build a [TelemetrySnapshot] from a full 13-byte [QosStatus] GATT read.
  ///
  /// If all core values are 0, treats as sparse/unknown (firmware not yet
  /// populating) rather than present-with-zero.
  static TelemetrySnapshot fromQosStatus(String edId, QosStatus status) {
    final allZero = status.rssi == 0 && status.pdr == 0 &&
        status.latency == 0 && status.jitter == 0;

    if (allZero) {
      // Firmware sends zeros when ED not in active session — treat as unknown
      return TelemetrySnapshot(
        edId: edId,
        profile: PayloadProfile.p1,
        lastUpdated: DateTime.now(),
      );
    }

    return TelemetrySnapshot(
      edId: edId,
      rssi: MetricValue.present(status.rssi),
      pdr: MetricValue.present(status.pdr.toDouble()),
      latency: MetricValue.present(status.latency),
      jitter: MetricValue.present(status.jitter),
      phy: MetricValue.present(status.phy),
      txPower: MetricValue.present(status.txPower),
      throughput: status.tp > 0
          ? MetricValue.present(status.tp)
          : const MetricValue(0, TelemetryValueState.present),
      profile: PayloadProfile.p1,
      lastUpdated: DateTime.now(),
    );
  }

  /// Build a [TelemetrySnapshot] from a 4-byte indexed STATUS notify.
  ///
  /// Indexed format only carries zone/profile/phy/tx — no RSSI/PDR/latency.
  /// These missing fields are marked as [sparse], not error.
  static TelemetrySnapshot fromIndexedStatus(String edId, QosStatus indexed) {
    return TelemetrySnapshot(
      edId: edId,
      rssi: const MetricValue.sparse(),
      pdr: const MetricValue.sparse(),
      latency: const MetricValue.sparse(),
      jitter: const MetricValue.sparse(),
      phy: MetricValue.present(indexed.phy),
      txPower: MetricValue.present(indexed.txPower),
      throughput: const MetricValue.sparse(),
      profile: PayloadProfile.p0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Build a [TelemetrySnapshot] from [QosMetricsV2] (20-byte notify).
  static TelemetrySnapshot fromMetricsV2(String edId, QosMetricsV2 metrics) {
    return TelemetrySnapshot(
      edId: edId,
      rssi: MetricValue.present(metrics.rssi),
      pdr: MetricValue.present(metrics.pdr / 100.0),
      latency: MetricValue.present(metrics.latency),
      jitter: MetricValue.present(metrics.jitter),
      phy: MetricValue.present(metrics.phy),
      txPower: MetricValue.present(metrics.txPower),
      throughput: MetricValue.present(metrics.tpBps),
      profile: PayloadProfile.p1,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a snapshot for a registered-but-not-online ED.
  /// All fields are [unknown] — not sparse, not stale, just never received.
  static TelemetrySnapshot notConnected(String edId) {
    return TelemetrySnapshot(
      edId: edId,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a snapshot for an ED whose Central data hasn't synced yet.
  static TelemetrySnapshot notSynced(String edId) {
    return TelemetrySnapshot(
      edId: edId,
      rssi: const MetricValue.notSynced(),
      pdr: const MetricValue.notSynced(),
      latency: const MetricValue.notSynced(),
      jitter: const MetricValue.notSynced(),
      phy: const MetricValue.notSynced(),
      txPower: const MetricValue.notSynced(),
      throughput: const MetricValue.notSynced(),
    );
  }

  /// Merge a new snapshot into an existing one, preserving last-valid values.
  ///
  /// If the new snapshot has sparse fields but the old one had present values,
  /// the old present values are kept (marked stale if too old).
  static TelemetrySnapshot merge(
    TelemetrySnapshot existing,
    TelemetrySnapshot incoming, {
    Duration staleThreshold = const Duration(seconds: 10),
  }) {
    return TelemetrySnapshot(
      edId: existing.edId,
      rssi: _mergeField(existing.rssi, incoming.rssi, incoming.lastUpdated, staleThreshold),
      pdr: _mergeField(existing.pdr, incoming.pdr, incoming.lastUpdated, staleThreshold),
      latency: _mergeField(existing.latency, incoming.latency, incoming.lastUpdated, staleThreshold),
      jitter: _mergeField(existing.jitter, incoming.jitter, incoming.lastUpdated, staleThreshold),
      phy: _mergeField(existing.phy, incoming.phy, incoming.lastUpdated, staleThreshold),
      txPower: _mergeField(existing.txPower, incoming.txPower, incoming.lastUpdated, staleThreshold),
      throughput: _mergeField(existing.throughput, incoming.throughput, incoming.lastUpdated, staleThreshold),
      profile: incoming.profile ?? existing.profile,
      profileSince: incoming.profile != existing.profile
          ? incoming.lastUpdated
          : existing.profileSince,
      lastUpdated: incoming.lastUpdated ?? existing.lastUpdated,
    );
  }

  static MetricValue<T> _mergeField<T extends num>(
    MetricValue<T> existing,
    MetricValue<T> incoming,
    DateTime? incomingTime,
    Duration staleThreshold,
  ) {
    // If incoming has a real value, use it
    if (incoming.hasValue) return incoming;

    // If incoming is sparse but existing had a value, keep existing as stale
    if (incoming.state == TelemetryValueState.sparse && existing.hasValue) {
      return MetricValue.stale(existing.value as T);
    }

    // Otherwise keep existing
    return existing;
  }
}
