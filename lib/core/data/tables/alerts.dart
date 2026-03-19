import 'package:drift/drift.dart';

class Alerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get severity => text()();
  TextColumn get type => text()();
  TextColumn get message => text().nullable()();
  BlobColumn get rawPayload => blob().nullable()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get resolvedAt => integer().nullable()();
}
