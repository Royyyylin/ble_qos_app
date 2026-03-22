import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';

/// Riverpod provider for auth session — shared across features.
/// ChangeNotifierProvider so widgets rebuild when role changes.
final authSessionProvider = ChangeNotifierProvider<AuthSession>((ref) {
  return AuthSession();
});
