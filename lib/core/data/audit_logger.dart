import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';

/// Global audit logger — call from any Riverpod context.
/// Automatically reads current auth role.
class AuditLogger {
  final Ref _ref;

  AuditLogger(this._ref);

  Future<void> log(String action, {String? targetDevice, String? detail}) async {
    try {
      final repo = _ref.read(auditRepositoryProvider);
      final role = _ref.read(authSessionProvider).currentRole;
      final roleStr = switch (role) {
        AuthRole.normal => 'Role-0',
        AuthRole.maintenance => 'Role-1',
        AuthRole.engineer => 'Role-2',
      };
      await repo.log(
        userRole: roleStr,
        action: action,
        targetDevice: targetDevice,
        detailAfter: detail,
      );
    } catch (e) {
      debugPrint('[AUDIT] log failed: $e');
    }
  }
}

/// Provider for AuditLogger.
final auditLoggerProvider = Provider<AuditLogger>((ref) => AuditLogger(ref));
