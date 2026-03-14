import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ble/ble_connector.dart';
import '../../core/domain/role_policy.dart';
import '../../core/domain/unlock_session.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/role_provider.dart';

/// Settings screen — app role switch, session info, disconnect.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRole = ref.watch(appRoleProvider);
    final session = ref.watch(unlockSessionProvider);
    final device = ref.watch(connectedDeviceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // App role
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('App Role'),
            subtitle: Text(_roleName(appRole)),
          ),
          const Divider(),

          // Role switch
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch to Patrol'),
            enabled: appRole != AppRole.patrol,
            onTap: () {
              session.lock();
              ref.read(appRoleProvider.notifier).state = AppRole.patrol;
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Switch to Installer'),
            subtitle: const Text('Requires deployment password'),
            enabled: appRole != AppRole.installer,
            onTap: () {
              ref.read(appRoleProvider.notifier).state = AppRole.installer;
            },
          ),
          ListTile(
            leading: const Icon(Icons.engineering),
            title: const Text('Switch to Engineer'),
            subtitle: const Text('Requires ENG_UNLOCK PIN'),
            enabled: appRole != AppRole.engineer,
            onTap: () {
              // Navigate to engineer screen for unlock
              Navigator.of(context).pushNamed('/engineer');
            },
          ),
          const Divider(),

          // Session info
          if (session.isUnlocked)
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.green),
              title: const Text('Engineer session active'),
              subtitle: Text('Remaining: ${session.remaining.inSeconds}s'),
              trailing: TextButton(
                onPressed: () => session.refresh(),
                child: const Text('Refresh'),
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
                session.lock();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        ],
      ),
    );
  }

  String _roleName(AppRole r) => switch (r) {
        AppRole.patrol => 'Patrol (read-only)',
        AppRole.installer => 'Installer',
        AppRole.engineer => 'Engineer',
      };
}
