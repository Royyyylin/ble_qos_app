import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';

/// Riverpod provider for auth session — shared across features.
/// Extracted from settings_screen.dart to avoid cross-feature coupling.
final authSessionProvider = Provider<AuthSession>((ref) => AuthSession());
