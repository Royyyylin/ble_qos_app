import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Dashboard tab — telemetry metrics display (spec §5, §6).
/// Subscribes to STATUS notify stream via statusStreamProvider.
/// Shows RSSI, Zone, PHY, TX Power, PDR, Interval as live MetricCards.
class DashboardTab extends ConsumerWidget {
  final String deviceId;

  const DashboardTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(statusStreamProvider);

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
            child: statusAsync.when(
              loading: () => GridView.count(
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
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (status) => GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _MetricCard(label: 'RSSI', value: '${status.rssi}', unit: 'dBm'),
                  _MetricCard(label: 'Zone', value: '${status.zone}', unit: ''),
                  _MetricCard(label: 'PHY', value: '${status.phy}', unit: ''),
                  _MetricCard(label: 'TX Power', value: '${status.txPower}', unit: 'dBm'),
                  _MetricCard(label: 'PDR', value: '${status.pdr}', unit: '%'),
                  _MetricCard(label: 'Interval', value: '${status.interval}', unit: 'ms'),
                ],
              ),
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
    final semanticsLabel = unit.isNotEmpty ? '$label: $value $unit' : '$label: $value';
    return Semantics(
      label: semanticsLabel,
      readOnly: true,
      child: Card(
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
      ),
    );
  }
}
