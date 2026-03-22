import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../identity/device_identity_service.dart';
import '../identity/drift_identity_repository.dart';
import 'database_provider.dart';

/// Provider for DeviceIdentityService — singleton, initialized once.
/// Call `await ref.read(identityServiceProvider).initialize()` at app startup.
final identityServiceProvider = Provider<DeviceIdentityService>((ref) {
  final db = ref.watch(databaseProvider);
  final repo = DriftIdentityRepository(db);
  final service = DeviceIdentityService(repo);
  return service;
});
