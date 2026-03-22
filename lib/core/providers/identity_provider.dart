import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../identity/device_identity_service.dart';
import '../identity/drift_identity_repository.dart';

/// Provider for the AppDatabase singleton.
/// In production, provide via ProviderScope override with actual QueryExecutor.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in ProviderScope with actual DB',
  );
});

/// Provider for DeviceIdentityService — singleton, initialized once.
final identityServiceProvider = Provider<DeviceIdentityService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = DriftIdentityRepository(db);
  final service = DeviceIdentityService(repo);
  return service;
});
