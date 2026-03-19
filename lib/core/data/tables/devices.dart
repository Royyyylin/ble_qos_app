import 'package:drift/drift.dart';

class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
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
