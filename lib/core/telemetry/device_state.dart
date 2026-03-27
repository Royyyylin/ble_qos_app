import 'telemetry_value_state.dart';
import 'telemetry_snapshot.dart';

/// Assignment state as defined in data-model.md / failover-policy.md.
/// App only displays this — Central is the authoritative owner.
enum AssignmentState {
  active,
  degraded,
  failover,
  orphaned,
  revoked,
  recovered,
  pending,
}

/// Per-ED device state for roster/detail display.
///
/// Combines identity, assignment, telemetry, and profile metadata.
/// All fields that may come from P0 sparse payload are nullable.
class EdDeviceState {
  /// Canonical identity — never changes.
  final String edId;       // ed:{ed_mac}
  final String edMac;

  /// Assignment — from Central sync, not authoritative in App.
  final String? activeGatewayId;  // gw:{gw_mac}
  final AssignmentState assignmentState;

  /// Display metadata.
  final String? alias;
  final String? firmwareName;  // BLE advertising name

  /// Telemetry — profile-aware, fields may be sparse.
  final TelemetrySnapshot? telemetry;

  /// Profile tracking.
  final PayloadProfile? lastPayloadProfile;
  final DateTime? profileSince;
  final bool isSparseProfile;

  /// Failover info (display only, not authoritative).
  final String? lastFailoverReason;
  final String? lastFailoverFrom;
  final String? lastFailoverTo;
  final DateTime? lastFailoverAt;

  const EdDeviceState({
    required this.edId,
    required this.edMac,
    this.activeGatewayId,
    this.assignmentState = AssignmentState.pending,
    this.alias,
    this.firmwareName,
    this.telemetry,
    this.lastPayloadProfile,
    this.profileSince,
    this.isSparseProfile = false,
    this.lastFailoverReason,
    this.lastFailoverFrom,
    this.lastFailoverTo,
    this.lastFailoverAt,
  });

  /// Display name following precedence: alias > firmware name > ed_id.
  String get displayName => alias ?? firmwareName ?? edId;

  /// Whether this ED has usable telemetry data.
  bool get hasTelemetry => telemetry != null && telemetry!.rssi.hasValue;
}

/// GW summary state for dashboard/roster header.
class GwSummaryState {
  final String gwId;       // gw:{gw_mac}
  final String gwMac;
  final String? alias;
  final String healthState;  // healthy / degraded / down
  final int capacityLimit;
  final int currentEdCount;
  final int priority;

  // Device info (from GATT or Central).
  final String? fwVersion;
  final int? uptimeSeconds;
  final int? resetCount;

  const GwSummaryState({
    required this.gwId,
    required this.gwMac,
    this.alias,
    this.healthState = 'healthy',
    this.capacityLimit = 8,
    this.currentEdCount = 0,
    this.priority = 1,
    this.fwVersion,
    this.uptimeSeconds,
    this.resetCount,
  });

  String get displayName => alias ?? gwId;
}

/// Sync state tracking for the App ↔ Central connection.
class SyncState {
  final int lastSyncedRevision;
  final DateTime? lastSyncAt;
  final bool isSyncing;
  final String? lastSyncError;
  final int pendingOpsCount;

  const SyncState({
    this.lastSyncedRevision = 0,
    this.lastSyncAt,
    this.isSyncing = false,
    this.lastSyncError,
    this.pendingOpsCount = 0,
  });
}

/// Auth session state for App ↔ Central JWT.
/// Separate from local PIN auth (which is UI gating only).
class CentralAuthState {
  final bool isAuthenticated;
  final String? username;
  final String? centralRole;  // viewer/operator/maintainer/engineer/admin
  final DateTime? tokenExpiresAt;

  const CentralAuthState({
    this.isAuthenticated = false,
    this.username,
    this.centralRole,
    this.tokenExpiresAt,
  });
}
