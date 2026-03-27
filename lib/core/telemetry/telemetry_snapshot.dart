import 'telemetry_value_state.dart';

/// A single telemetry metric value with its state.
///
/// Wraps a nullable numeric value with [TelemetryValueState] so UI can
/// distinguish between "field absent due to P0 sparse" vs "stale" vs "unknown".
class MetricValue<T extends num> {
  final T? value;
  final TelemetryValueState state;

  const MetricValue(this.value, this.state);

  /// Present value from P1 complete payload.
  const MetricValue.present(T this.value) : state = TelemetryValueState.present;

  /// Field absent due to P0 sparse profile. Not an error.
  const MetricValue.sparse() : value = null, state = TelemetryValueState.sparse;

  /// Value was once present but exceeded freshness threshold.
  const MetricValue.stale(T this.value) : state = TelemetryValueState.stale;

  /// Never received for this device.
  const MetricValue.unknown() : value = null, state = TelemetryValueState.unknown;

  /// Central has not synced this device yet.
  const MetricValue.notSynced() : value = null, state = TelemetryValueState.notSynced;

  bool get hasValue => value != null;
  bool get isDisplayable => state == TelemetryValueState.present || state == TelemetryValueState.stale;
}

/// Per-ED telemetry snapshot with profile-aware nullable fields.
///
/// All metric fields are [MetricValue] to track why a value may be absent.
/// The [profile] field tells us whether this snapshot came from P0/P1/P2.
class TelemetrySnapshot {
  final String edId;

  // Core QoS metrics — may be absent in P0
  final MetricValue<int> rssi;        // dBm
  final MetricValue<double> pdr;      // 0-100 %
  final MetricValue<int> latency;     // ms
  final MetricValue<int> jitter;      // ms

  // Config/info metrics — often absent in P0
  final MetricValue<int> phy;         // 1M=1, 2M=2, Coded=4
  final MetricValue<int> txPower;     // dBm
  final MetricValue<int> throughput;  // B/s (0 = N/A in non-TP mode)

  // Profile metadata
  final PayloadProfile? profile;
  final DateTime? profileSince;
  final DateTime? lastUpdated;

  const TelemetrySnapshot({
    required this.edId,
    this.rssi = const MetricValue.unknown(),
    this.pdr = const MetricValue.unknown(),
    this.latency = const MetricValue.unknown(),
    this.jitter = const MetricValue.unknown(),
    this.phy = const MetricValue.unknown(),
    this.txPower = const MetricValue.unknown(),
    this.throughput = const MetricValue.unknown(),
    this.profile,
    this.profileSince,
    this.lastUpdated,
  });

  TelemetrySnapshot copyWith({
    MetricValue<int>? rssi,
    MetricValue<double>? pdr,
    MetricValue<int>? latency,
    MetricValue<int>? jitter,
    MetricValue<int>? phy,
    MetricValue<int>? txPower,
    MetricValue<int>? throughput,
    PayloadProfile? profile,
    DateTime? profileSince,
    DateTime? lastUpdated,
  }) {
    return TelemetrySnapshot(
      edId: edId,
      rssi: rssi ?? this.rssi,
      pdr: pdr ?? this.pdr,
      latency: latency ?? this.latency,
      jitter: jitter ?? this.jitter,
      phy: phy ?? this.phy,
      txPower: txPower ?? this.txPower,
      throughput: throughput ?? this.throughput,
      profile: profile ?? this.profile,
      profileSince: profileSince ?? this.profileSince,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
