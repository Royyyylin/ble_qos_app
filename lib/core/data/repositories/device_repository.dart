import 'package:drift/drift.dart';
import '../database.dart';

/// Device CRUD repository — spec §7.1.
class DeviceRepository {
  final AppDatabase _db;

  DeviceRepository(this._db);

  Future<List<Device>> getAllDevices() => _db.select(_db.devices).get();

  Future<List<Device>> getDevicesByNetwork(int networkId) =>
      (_db.select(_db.devices)..where((d) => d.networkId.equals(networkId)))
          .get();

  Future<Device?> getDevice(String id) =>
      (_db.select(_db.devices)..where((d) => d.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertDevice({
    required String id,
    required String name,
    required String role,
    required String status,
    int? networkId,
    String? groupName,
    int? rssi,
    int? zone,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.devices).insertOnConflictUpdate(
          DevicesCompanion.insert(
            id: id,
            name: Value(name),
            role: role,
            networkId: Value(networkId),
            groupName: Value(groupName),
            status: status,
            rssi: Value(rssi),
            zone: Value(zone),
            lastSeen: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateStatus(String id, String status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.devices)..where((d) => d.id.equals(id))).write(
      DevicesCompanion(
        status: Value(status),
        lastSeen: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
