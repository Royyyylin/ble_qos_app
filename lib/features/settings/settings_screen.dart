import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/ble/ble_connector.dart';
import '../../core/providers/device_provider.dart';

/// Riverpod provider for auth session — replaces legacy role_provider + unlock_session.
final authSessionProvider = Provider<AuthSession>((ref) => AuthSession());

/// Settings screen — auth role switch, session info, disconnect.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final device = ref.watch(connectedDeviceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Current role
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Auth Role'),
            subtitle: Text(_roleName(session.currentRole)),
          ),
          const Divider(),

          // Role elevation
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Normal Mode'),
            enabled: session.isElevated,
            onTap: () => session.demote(),
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Elevate to Maintenance'),
            subtitle: const Text('Requires 6-digit PIN'),
            enabled: session.currentRole != AuthRole.maintenance,
            onTap: () => session.elevate(AuthRole.maintenance),
          ),
          ListTile(
            leading: const Icon(Icons.engineering),
            title: const Text('Elevate to Engineer'),
            subtitle: const Text('Requires ENG_UNLOCK PIN'),
            enabled: session.currentRole != AuthRole.engineer,
            onTap: () => session.elevate(AuthRole.engineer),
          ),
          const Divider(),

          // Session info
          if (session.isElevated)
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.green),
              title: Text('${_roleName(session.currentRole)} session active'),
              subtitle: Text(
                'Idle timeout: ${session.currentRole.idleTimeout.inMinutes}min',
              ),
            ),

          // Connection
          if (device != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bluetooth_connected),
              title: Text('Connected: ${device.name}'),
              subtitle: Text('Mode: ${device.mode.name}'),
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth_disabled, color: Colors.red),
              title: const Text('Disconnect'),
              onTap: () {
                ref.read(bleConnectorProvider).disconnect();
                ref.read(connectedDeviceProvider.notifier).disconnect();
                session.demote();
                context.go('/');
              },
            ),
          ],
        ],
      ),
    );
  }

  String _roleName(AuthRole r) => switch (r) {
        AuthRole.normal => 'Normal (read-only)',
        AuthRole.maintenance => 'Maintenance',
        AuthRole.engineer => 'Engineer',
      };
}
