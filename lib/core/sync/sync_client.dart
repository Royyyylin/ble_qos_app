import '../telemetry/device_state.dart';

/// Sync client interface for App ↔ Central communication.
///
/// This is a skeleton — actual HTTP implementation deferred until
/// Central A3 (auth) is ready. App code programs against this interface.
abstract class SyncClient {
  /// Delta sync: pull all changes since [sinceRevision].
  /// Returns updated device states + new max revision.
  Future<SyncResult> deltaSync(int sinceRevision);

  /// Full sync: equivalent to deltaSync(0).
  Future<SyncResult> fullSync();

  /// Push a rename alias command.
  /// Returns updated metadata on success, throws on conflict/error.
  Future<void> renameAlias(String centralRef, String alias, int revision);

  /// Check if Central is reachable.
  Future<bool> isReachable();
}

/// Result of a delta/full sync operation.
class SyncResult {
  final List<EdDeviceState> devices;
  final List<GwSummaryState> gateways;
  final int maxRevision;

  const SyncResult({
    required this.devices,
    required this.gateways,
    required this.maxRevision,
  });
}

/// Offline fallback implementation — always returns empty/cached data.
/// Used when Central is unreachable.
class OfflineSyncClient implements SyncClient {
  @override
  Future<SyncResult> deltaSync(int sinceRevision) async =>
      const SyncResult(devices: [], gateways: [], maxRevision: 0);

  @override
  Future<SyncResult> fullSync() async => deltaSync(0);

  @override
  Future<void> renameAlias(String centralRef, String alias, int revision) async {
    // Offline: no-op, pending op stays in local queue
  }

  @override
  Future<bool> isReachable() async => false;
}
