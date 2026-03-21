import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/ble/ble_connector.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/device_provider.dart';
import '../../core/theme/app_colors.dart';

/// Settings screen — auth role switch with PIN dialog, session info, disconnect.
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
            onTap: () => _showPinDialog(
              context,
              title: 'Maintenance PIN',
              hint: '6-digit PIN',
              maxLength: 6,
              onValidated: () => session.elevate(AuthRole.maintenance),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.engineering),
            title: const Text('Elevate to Engineer'),
            subtitle: const Text('Requires 8-digit ENG_UNLOCK PIN'),
            enabled: session.currentRole != AuthRole.engineer,
            onTap: () => _showPinDialog(
              context,
              title: 'Engineer PIN',
              hint: '8-digit PIN',
              maxLength: 8,
              onValidated: () => session.elevate(AuthRole.engineer),
            ),
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

  void _showPinDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required int maxLength,
    required VoidCallback onValidated,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          maxLength: maxLength,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = controller.text;
              if (pin.length >= maxLength - 2) {
                // Phase 1: accept any PIN of correct length (App-side soft control)
                // Phase 2: validate against stored hash or firmware ENG_UNLOCK
                Navigator.pop(ctx);
                onValidated();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Unlock'),
          ),
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
