import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Control tab — QoS profile selector and CTRL write buttons (spec §6).
/// Permission-gated by PermissionGuard.canWrite().
class ControlTab extends StatelessWidget {
  final String deviceId;

  const ControlTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QoS Control',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune, color: AppColors.primary),
              title: const Text('QoS Profile'),
              subtitle: const Text('Select active profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show profile selector
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.send, color: AppColors.primary),
              title: const Text('Write CTRL'),
              subtitle: const Text('Send control command'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: CTRL write with permission check
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_ethernet, color: AppColors.primary),
              title: const Text('Gateway Config'),
              subtitle: const Text('Edit GW_CFG parameters'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
        ],
      ),
    );
  }
}
