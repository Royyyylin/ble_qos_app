import 'package:drift/drift.dart';

class Devices extends Table {
  /// StableId (UUIDv4) — primary key after identity migration.
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  /// Platform MAC address — added in schema v2 for BLE operations.
  TextColumn get mac => text().nullable()();
  TextColumn get role => text()();
  IntColumn get networkId => integer().nullable()();
  TextColumn get groupName => text().nullable()();
  TextColumn get status => text()();
  IntColumn get rssi => integer().nullable()();
  IntColumn get zone => integer().nullable()();
  TextColumn get firmwareVer => text().nullable()();
  TextColumn get tags => text().nullable()();       // JSON array
  TextColumn get capabilities => text().nullable()(); // JSON
  IntColumn get lastSeen => integer()();
  TextColumn get configJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
