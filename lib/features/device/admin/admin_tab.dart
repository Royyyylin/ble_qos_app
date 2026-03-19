import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Admin tab — engineer-only actions (spec §11).
/// ENG_UNLOCK, CTRL read, GW_CFG editor, CMD console, PIN management.
/// Replaces old EngineerScreen.
class AdminTab extends StatelessWidget {
  final String deviceId;

  const AdminTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Engineer Admin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_open, color: AppColors.warning),
              title: const Text('ENG_UNLOCK'),
              subtitle: const Text('Unlock engineer mode on device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: ENG_UNLOCK flow
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.terminal, color: AppColors.primary),
              title: const Text('CMD Console'),
              subtitle: const Text('Send raw commands'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: CMD console
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('GW_CFG Editor'),
              subtitle: const Text('Edit gateway configuration'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key, color: AppColors.secondary),
              title: const Text('PIN Management'),
              subtitle: const Text('Set engineer PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: PIN management
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.memory, color: AppColors.primary),
              title: const Text('MODE / ROLE'),
              subtitle: const Text('Change device mode or role'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: MODE/ROLE write
              },
            ),
          ),
        ],
      ),
    );
  }
}
