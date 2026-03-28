import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../telemetry/device_state.dart';
import '../telemetry/telemetry_snapshot.dart';

/// Per-ED telemetry snapshot state.
/// Keyed by edId (canonical identity).
final telemetrySnapshotMapProvider =
    StateProvider<Map<String, TelemetrySnapshot>>((ref) => {});

/// Per-ED device state for roster display.
final edDeviceStateMapProvider =
    StateProvider<Map<String, EdDeviceState>>((ref) => {});

/// GW summary state for dashboard.
final gwSummaryProvider = StateProvider<GwSummaryState?>((ref) => null);

/// App ↔ Central sync state.
final syncStateProvider = StateProvider<SyncState>((ref) => const SyncState());

/// Central JWT auth state (separate from local PIN).
final centralAuthProvider =
    StateProvider<CentralAuthState>((ref) => const CentralAuthState());
