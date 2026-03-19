import 'package:drift/drift.dart';
import '../database.dart';

/// Alert CRUD repository with aggregation — spec §7.2.
class AlertRepository {
  final AppDatabase _db;

  AlertRepository(this._db);

  /// Get all unresolved alerts, newest first.
  Future<List<Alert>> getUnresolved() =>
    (_db.select(_db.alerts)
      ..where((a) => a.resolvedAt.isNull())
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
    .get();

  /// Get recent alerts regardless of status, newest first.
  Future<List<Alert>> getRecent({int limit = 50}) =>
    (_db.select(_db.alerts)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit))
    .get();

  /// Insert a new alert record.
  Future<void> insertAlert({
    required String? deviceId,
    required String severity,
    required String type,
    String? message,
  }) async {
    await _db.into(_db.alerts).insert(
      AlertsCompanion.insert(
        deviceId: Value(deviceId),
        severity: severity,
        type: type,
        message: Value(message),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Mark an alert as acknowledged and resolved.
  Future<void> acknowledge(int id) async {
    await (_db.update(_db.alerts)..where((a) => a.id.equals(id)))
      .write(AlertsCompanion(
        acknowledged: const Value(true),
        resolvedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
  }

  /// Prune alerts older than [maxAge] — spec §7.2 (default 7 days).
  Future<int> prune(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return (_db.delete(_db.alerts)..where((a) => a.createdAt.isSmallerThanValue(cutoff))).go();
  }
}
