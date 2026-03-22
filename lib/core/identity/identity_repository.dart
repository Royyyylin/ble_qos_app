import 'device_identity.dart';

/// Repository interface for MAC↔StableId persistence.
/// Infrastructure layer provides the Drift-backed implementation.
abstract class IdentityRepository {
  /// Find StableId by MAC address. Returns null if not yet assigned.
  Future<String?> findStableIdByMac(String mac);

  /// Find MAC by StableId. Returns null if unknown.
  Future<String?> findMacByStableId(String stableId);

  /// Persist a new DeviceIdentity mapping.
  Future<void> save(DeviceIdentity identity);

  /// Get all persisted identity mappings (for in-memory cache warm-up).
  Future<List<DeviceIdentity>> getAll();
}
