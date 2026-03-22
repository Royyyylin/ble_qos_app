import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/database_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/device/device_screen.dart';
import 'features/provisioning/provisioning_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/audit/audit_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ScannerScreen()),
    GoRoute(path: '/device/:id', builder: (_, state) =>
      DeviceScreen(
        deviceId: state.pathParameters['id']!,
        showControlTab: true,
      )),
    GoRoute(path: '/provisioning/:id', builder: (_, state) =>
      ProvisioningScreen(deviceId: state.pathParameters['id']!)),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/audit', builder: (_, _) => const AuditScreen()),
  ],
);

void main() {
  runApp(const ProviderScope(child: BleQosApp()));
}

class BleQosApp extends ConsumerStatefulWidget {
  const BleQosApp({super.key});

  @override
  ConsumerState<BleQosApp> createState() => _BleQosAppState();
}

class _BleQosAppState extends ConsumerState<BleQosApp> {
  @override
  void initState() {
    super.initState();
    // Data retention pruning on app start (spec §7.2)
    Future.microtask(() {
      final db = ref.read(databaseProvider);
      runDataRetention(db);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BLE QoS Monitor',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
