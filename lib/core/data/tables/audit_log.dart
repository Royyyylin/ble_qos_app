import 'package:drift/drift.dart';

class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userRole => text()();
  TextColumn get action => text()();
  TextColumn get targetDevice => text().nullable()();
  TextColumn get detailBefore => text().nullable()();
  TextColumn get detailAfter => text().nullable()();
  IntColumn get createdAt => integer()();
}
