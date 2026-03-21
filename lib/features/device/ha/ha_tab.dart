import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// HA status tab — subscribes to HA_HB notify, parses 21-byte heartbeat,
/// displays HA role, epoch, heartbeat count, failover event (spec §10).
class HaTab extends ConsumerWidget {
  final String deviceId;

  const HaTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hbAsync = ref.watch(haHeartbeatStreamProvider);

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
              child: hbAsync.when(
                loading: () => _buildFields(context, null),
                error: (e, _) => _buildFields(context, null, error: '$e'),
                data: (hb) => _buildFields(context, hb),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failover History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: hbAsync.when(
              loading: () => const Center(
                child: Text('Waiting for heartbeat...', style: TextStyle(color: AppColors.textSecondary)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              ),
              data: (hb) => _buildFailoverInfo(context, hb),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(BuildContext context, HaHeartbeat? hb, {String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        _HaInfoRow(label: 'HA Role', value: hb?.haRoleLabel ?? '--'),
        const Divider(),
        _HaInfoRow(label: 'Epoch', value: hb?.epoch.toString() ?? '--'),
        const Divider(),
        _HaInfoRow(label: 'Heartbeat', value: hb?.heartbeatCount.toString() ?? '--'),
        const Divider(),
        _HaInfoRow(label: 'Peer Status', value: hb?.peerStatusLabel ?? '--'),
      ],
    );
  }

  Widget _buildFailoverInfo(BuildContext context, HaHeartbeat hb) {
    if (hb.lastFailoverTimestamp == 0) {
      return const Center(
        child: Text('No failover events', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    final failoverTime = DateTime.fromMillisecondsSinceEpoch(
      hb.lastFailoverTimestamp * 1000,
    );
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.swap_horiz, color: AppColors.warning),
          title: Text('Last failover: ${failoverTime.toLocal()}'),
          subtitle: Text('Reason code: 0x${hb.lastFailoverReason.toRadixString(16)}'),
        ),
      ],
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
