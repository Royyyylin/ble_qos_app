import 'package:drift/drift.dart';

/// Drift table for DeviceIdentity persistence — MAC↔StableId mapping.
class DeviceIdentities extends Table {
  /// App-generated UUIDv4 stable identifier.
  TextColumn get stableId => text()();

  /// Platform BLE remote identifier (MAC on Android, UUID on iOS).
  TextColumn get mac => text().unique()();

  /// User-assigned alias (stored locally, synced from GATT DEVICE_ALIAS).
  TextColumn get alias => text().nullable()();

  /// Timestamp when identity was first assigned (epoch ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {stableId};
}
