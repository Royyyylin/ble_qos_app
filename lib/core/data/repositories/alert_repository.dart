import 'package:drift/drift.dart';
import '../database.dart';

class AlertRepository {
  final AppDatabase _db;

  AlertRepository(this._db);

  Future<List<Alert>> getUnresolved() =>
    (_db.select(_db.alerts)
      ..where((a) => a.resolvedAt.isNull())
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
    .get();

  Future<List<Alert>> getRecent({int limit = 50}) =>
    (_db.select(_db.alerts)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit))
    .get();

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

  Future<void> acknowledge(int id) async {
    (_db.update(_db.alerts)..where((a) => a.id.equals(id)))
      .write(AlertsCompanion(
        acknowledged: const Value(true),
        resolvedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
  }

  /// Prune alerts older than duration — spec 7.2 (7 days).
  Future<int> prune(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return (_db.delete(_db.alerts)..where((a) => a.createdAt.isSmallerThanValue(cutoff))).go();
  }
}
