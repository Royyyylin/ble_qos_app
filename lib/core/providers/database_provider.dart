import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repositories/alert_repository.dart';
import '../data/repositories/audit_repository.dart';

/// Singleton database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(NativeDatabase.memory());
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
