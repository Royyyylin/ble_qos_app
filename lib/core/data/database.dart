import 'package:drift/drift.dart';

import 'tables/devices.dart';
import 'tables/alerts.dart';
import 'tables/audit_log.dart';
import 'tables/device_telemetry.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Devices, Alerts, AuditLog, DeviceTelemetry])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
