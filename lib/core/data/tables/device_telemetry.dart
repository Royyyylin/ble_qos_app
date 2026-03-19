import 'package:drift/drift.dart';

class DeviceTelemetry extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text()();
  IntColumn get timestamp => integer()();
  IntColumn get rssi => integer().nullable()();
  IntColumn get zone => integer().nullable()();
  TextColumn get sensorData => text().nullable()(); // JSON

  @override
  List<Set<Column>> get uniqueKeys => [{deviceId, timestamp}];
}
