import 'package:drift/drift.dart';
import '../database.dart';

/// Audit log CRUD repository — spec §7.2 / §12.
class AuditRepository {
  final AppDatabase _db;

  AuditRepository(this._db);

  /// Get all audit entries, newest first.
  Future<List<AuditLogData>> getAll({int limit = 100}) =>
    (_db.select(_db.auditLog)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit))
    .get();

  /// Get audit entries filtered by [userRole], newest first.
  Future<List<AuditLogData>> getByRole(String userRole, {int limit = 100}) =>
    (_db.select(_db.auditLog)
      ..where((a) => a.userRole.equals(userRole))
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit))
    .get();

  /// Record an audit log entry.
  Future<void> log({
    required String userRole,
    required String action,
    String? targetDevice,
    String? detailBefore,
    String? detailAfter,
  }) async {
    await _db.into(_db.auditLog).insert(
      AuditLogCompanion.insert(
        userRole: userRole,
        action: action,
        targetDevice: Value(targetDevice),
        detailBefore: Value(detailBefore),
        detailAfter: Value(detailAfter),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Prune entries older than [maxAge] — spec §7.2 (default 90 days).
  Future<int> prune(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return (_db.delete(_db.auditLog)..where((a) => a.createdAt.isSmallerThanValue(cutoff))).go();
  }
}
