import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/role_policy.dart';

/// Current app-side user role.
final appRoleProvider = StateProvider<AppRole>((ref) => AppRole.patrol);
