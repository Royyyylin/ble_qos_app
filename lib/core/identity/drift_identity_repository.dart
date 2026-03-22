import 'package:drift/drift.dart';

import '../data/database.dart' hide DeviceIdentity;
import 'device_identity.dart';
import 'identity_repository.dart';

/// Drift-backed implementation of IdentityRepository.
class DriftIdentityRepository implements IdentityRepository {
  final AppDatabase _db;

  DriftIdentityRepository(this._db);

  @override
  Future<String?> findStableIdByMac(String mac) async {
    final row = await (_db.select(_db.deviceIdentities)
          ..where((t) => t.mac.equals(mac)))
        .getSingleOrNull();
    return row?.stableId;
  }

  @override
  Future<String?> findMacByStableId(String stableId) async {
    final row = await (_db.select(_db.deviceIdentities)
          ..where((t) => t.stableId.equals(stableId)))
        .getSingleOrNull();
    return row?.mac;
  }

  @override
  Future<void> save(DeviceIdentity identity) async {
    await _db.into(_db.deviceIdentities).insertOnConflictUpdate(
      DeviceIdentitiesCompanion.insert(
        stableId: identity.stableId,
        mac: identity.mac,
        createdAt: identity.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<List<DeviceIdentity>> getAll() async {
    final rows = await _db.select(_db.deviceIdentities).get();
    return rows
        .map((r) => DeviceIdentity(
              stableId: r.stableId,
              mac: r.mac,
              createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
            ))
        .toList();
  }
}
