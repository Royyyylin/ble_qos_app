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

  /// Set user-assigned alias for a device. Pass null to clear.
  Future<void> setAlias(String stableId, String? alias);

  /// Get alias for a device. Returns null if not set.
  Future<String?> getAlias(String stableId);

  /// Get all aliases as stableId→alias map (for cache warm-up).
  Future<Map<String, String>> getAllAliases();
}
