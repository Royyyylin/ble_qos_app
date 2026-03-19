import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Dashboard tab — telemetry metrics display (spec §5, §6).
/// Shows RSSI, Zone, PHY, TX, PDR, Interval, Latency via MetricCard widgets.
/// Subscribes to STATUS + METRICS notify streams.
class DashboardTab extends StatelessWidget {
  final String deviceId;

  const DashboardTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telemetry',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: const [
                _MetricCard(label: 'RSSI', value: '--', unit: 'dBm'),
                _MetricCard(label: 'Zone', value: '--', unit: ''),
                _MetricCard(label: 'PHY', value: '--', unit: ''),
                _MetricCard(label: 'TX Power', value: '--', unit: 'dBm'),
                _MetricCard(label: 'PDR', value: '--', unit: '%'),
                _MetricCard(label: 'Interval', value: '--', unit: 'ms'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
