import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ed_roster_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Zone label from numeric value.
String _zoneLabel(int zone) => switch (zone) {
      0 => 'NEAR',
      1 => 'MID',
      2 => 'FAR',
      3 => 'EDGE',
      _ => '?',
    };

/// Profile label from numeric value.
String _profileLabel(int profile) => switch (profile) {
      0 => 'FAST',
      1 => 'BALANCED',
      2 => 'ROBUST',
      _ => '?',
    };

/// ED Roster tab — shows EDs in the same network as the connected GW.
/// Data sources: scan results (device info) + GW indexed STATUS notify (QoS metrics).
class EdRosterTab extends ConsumerWidget {
  final String deviceId;

  const EdRosterTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(edRosterProvider);

    if (roster.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices_other, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'No End Devices found in this network',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'EDs will appear here once discovered via scanning',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roster.length,
      itemBuilder: (context, index) {
        final entry = roster[index];
        return _EdRosterTile(entry: entry);
      },
    );
  }
}

class _EdRosterTile extends StatelessWidget {
  final EdRosterEntry entry;

  const _EdRosterTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final device = entry.device;
    final status = entry.gwStatus;
    final connected = entry.isConnectedToGw;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          connected ? Icons.link : Icons.link_off,
          color: connected ? AppColors.success : AppColors.stale,
          size: 20,
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: connected && status != null
            ? Text(
                'Zone: ${_zoneLabel(status.zone)} | Profile: ${_profileLabel(status.profile)} | TX: ${status.txPower} dBm',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              )
            : const Text(
                'Not connected to GW',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${device.smoothedRssi.round()} dBm',
              style: TextStyle(
                color: device.smoothedRssi > -60
                    ? AppColors.success
                    : device.smoothedRssi > -80
                        ? AppColors.warning
                        : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            _connectionBadge(connected),
          ],
        ),
      ),
    );
  }

  Widget _connectionBadge(bool connected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: connected
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.stale.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        connected ? 'Online' : 'Offline',
        style: TextStyle(
          color: connected ? AppColors.success : AppColors.stale,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
