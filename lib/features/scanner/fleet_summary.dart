import 'package:flutter/material.dart';

import '../../core/ble/ble_models.dart';
import '../../core/theme/app_colors.dart';

/// Fleet summary stat cards — spec §4, Fleet Overview Dashboard.
/// Shows online/stale/offline device counts.
class FleetSummary extends StatelessWidget {
  const FleetSummary({super.key, required this.devices});

  final List<ScannedDevice> devices;

  @override
  Widget build(BuildContext context) {
    final online = devices.where((d) => d.status == DeviceStatus.online).length;
    final stale = devices.where((d) => d.status == DeviceStatus.stale).length;
    final offline = devices.where((d) => d.status == DeviceStatus.offline).length;

    return Semantics(
      label: 'Fleet summary: $online online, $stale stale, $offline offline',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _StatCard(label: 'Online', count: online, color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Stale', count: stale, color: AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Offline', count: offline, color: AppColors.error)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
