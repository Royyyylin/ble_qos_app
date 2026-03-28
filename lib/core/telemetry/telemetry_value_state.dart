/// Telemetry value state — distinguishes why a metric may be absent.
///
/// P0 sparse payload (long-range survival) may omit fields intentionally.
/// This enum prevents conflating "sparse" with "stale", "unknown", or "error".
enum TelemetryValueState {
  /// Value present from a complete P1 payload.
  present,

  /// Field absent because the payload came from P0 sparse profile.
  /// This is normal behavior, not an error.
  sparse,

  /// Value was once present but has exceeded freshness threshold.
  stale,

  /// Field has never been received for this device.
  unknown,

  /// Central has not yet synced data for this device.
  notSynced,
}

/// Payload profile indicating the completeness level of received telemetry.
///
/// Firmware sends different profiles depending on link quality / distance:
/// - P0: long-range survival, minimal fields
/// - P1: normal operation, fields mostly complete
/// - P2: engineering/debug, reserved for v1
enum PayloadProfile {
  /// Long-range survival — minimal identity + core measurement only.
  /// Dedup/ordering only approximate. Fields intentionally sparse.
  p0,

  /// Normal operation — fields mostly complete, dedup/ordering more reliable.
  p1,

  /// Engineering/debug — v1 reserved, Central does not assume regular receipt.
  p2,
}
