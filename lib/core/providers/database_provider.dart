import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../data/database.dart';
import '../data/repositories/alert_repository.dart';
import '../data/repositories/audit_repository.dart';

/// Persistent database path (resolved once at startup).
String? _dbPath;

/// Initialize DB path before creating provider. Call from main().
Future<void> initDatabasePath() async {
  final dir = await getApplicationDocumentsDirectory();
  _dbPath = p.join(dir.path, 'ble_qos.db');
}

/// Singleton database instance — persistent file storage.
final databaseProvider = Provider<AppDatabase>((ref) {
  final executor = _dbPath != null
      ? NativeDatabase(File(_dbPath!))
      : NativeDatabase.memory(); // fallback for tests
  final db = AppDatabase(executor);
  ref.onDispose(() => db.close());
  return db;
});

/// Audit repository backed by the singleton database.
final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(databaseProvider));
});

/// Alert repository.
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(ref.watch(databaseProvider));
});

/// Live stream of audit log entries (newest first, limit 200).
final auditEntriesProvider = StreamProvider<List<AuditLogData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.auditLog)
        ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
        ..limit(200))
      .watch();
});

/// Data retention — prune old data on app start (spec §7.2).
/// Telemetry: 24h, Alerts: 7d, Audit: 90d.
Future<void> runDataRetention(AppDatabase db) async {
  final audit = AuditRepository(db);
  final alerts = AlertRepository(db);
  await Future.wait([
    audit.prune(const Duration(days: 90)),
    alerts.prune(const Duration(days: 7)),
    // Telemetry prune: delete records older than 24h
    (db.delete(db.deviceTelemetry)
          ..where((t) => t.timestamp.isSmallerThanValue(
              DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .millisecondsSinceEpoch)))
        .go(),
  ]);
}
