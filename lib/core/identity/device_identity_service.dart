import 'dart:math';

import 'device_identity.dart';
import 'identity_repository.dart';

/// Resolves or assigns StableId (UUIDv4) for BLE devices.
/// Uses an in-memory cache populated at startup to support synchronous
/// resolution in scan callbacks. Async writes persist to IdentityRepository.
class DeviceIdentityService {
  final IdentityRepository _repository;

  /// In-memory cache: MAC → StableId
  final _macToStableId = <String, String>{};

  /// Reverse cache: StableId → MAC
  final _stableIdToMac = <String, String>{};

  DeviceIdentityService(this._repository);

  /// Load all persisted mappings into in-memory cache.
  /// Must be called once at app startup before scan begins.
  Future<void> initialize() async {
    final all = await _repository.getAll();
    for (final identity in all) {
      _macToStableId[identity.mac] = identity.stableId;
      _stableIdToMac[identity.stableId] = identity.mac;
    }
  }

  /// Async resolve: lookup or generate+persist a StableId for [mac].
  Future<String> resolveOrAssign(String mac) async {
    final existing = _macToStableId[mac];
    if (existing != null) return existing;

    final stableId = _generateUuidV4();
    final identity = DeviceIdentity(stableId: stableId, mac: mac);
    _macToStableId[mac] = stableId;
    _stableIdToMac[stableId] = mac;
    await _repository.save(identity);
    return stableId;
  }

  /// Synchronous resolve: lookup from cache or generate+queue persist.
  /// Safe to call from scan callbacks. New mappings are persisted async.
  String resolveOrAssignSync(String mac) {
    final existing = _macToStableId[mac];
    if (existing != null) return existing;

    final stableId = _generateUuidV4();
    final identity = DeviceIdentity(stableId: stableId, mac: mac);
    _macToStableId[mac] = stableId;
    _stableIdToMac[stableId] = mac;
    // Fire-and-forget persist — cache is authoritative
    _repository.save(identity);
    return stableId;
  }

  /// Resolve StableId back to MAC for BLE operations.
  /// Returns null if unknown.
  String? resolveToMac(String stableId) => _stableIdToMac[stableId];

  /// Generate a UUIDv4 string.
  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // Set version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant 10
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
