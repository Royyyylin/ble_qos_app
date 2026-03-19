import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// HA status tab — displays Active/Standby role, epoch, heartbeat,
/// failover history (spec §10).
class HaTab extends StatelessWidget {
  final String deviceId;

  const HaTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'High Availability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HaInfoRow(label: 'HA Role', value: '--'),
                  const Divider(),
                  _HaInfoRow(label: 'Epoch', value: '--'),
                  const Divider(),
                  _HaInfoRow(label: 'Heartbeat', value: '--'),
                  const Divider(),
                  _HaInfoRow(label: 'Peer Status', value: '--'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failover History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Center(
              child: Text(
                'No failover events',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HaInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _HaInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
