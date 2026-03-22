import 'package:drift/drift.dart';

import 'tables/devices.dart';
import 'tables/device_identities.dart';
import 'tables/alerts.dart';
import 'tables/audit_log.dart';
import 'tables/device_telemetry.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Devices, DeviceIdentities, Alerts, AuditLog, DeviceTelemetry])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Schema v2: add DeviceIdentities table + mac column to Devices
        await migrator.createTable(deviceIdentities);
        await migrator.addColumn(devices, devices.mac);
      }
    },
  );
}
