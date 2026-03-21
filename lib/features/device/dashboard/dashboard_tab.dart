import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Metric definition: label + unit. Values come from QosStatus at runtime.
typedef _MetricDef = ({String label, String unit, String Function(QosStatus s) valueOf});

/// Dashboard tab — telemetry metrics display (spec §5, §6).
/// Subscribes to STATUS notify stream via statusStreamProvider.
/// Shows RSSI, Zone, PHY, TX Power, PDR, Interval as live MetricCards.
class DashboardTab extends ConsumerWidget {
  final String deviceId;

  const DashboardTab({super.key, required this.deviceId});

  /// Single source of truth for which metrics to display and how to read them.
  static final List<_MetricDef> _metrics = [
    (label: 'RSSI',     unit: 'dBm', valueOf: (s) => '${s.rssi}'),
    (label: 'Zone',     unit: '',    valueOf: (s) => '${s.zone}'),
    (label: 'PHY',      unit: '',    valueOf: (s) => '${s.phy}'),
    (label: 'TX Power', unit: 'dBm', valueOf: (s) => '${s.txPower}'),
    (label: 'PDR',      unit: '%',   valueOf: (s) => '${s.pdr}'),
    (label: 'Interval', unit: 'ms',  valueOf: (s) => '${s.interval}'),
  ];

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
              loading: () => _buildGrid(null),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (status) => _buildGrid(status),
            ),
          ),
        ],
      ),
    );
  }

  /// Build metric grid. When [status] is null, shows '--' placeholders.
  Widget _buildGrid(QosStatus? status) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final m in _metrics)
          _MetricCard(
            label: m.label,
            value: status != null ? m.valueOf(status) : '--',
            unit: m.unit,
          ),
      ],
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
                      fontFamily: AppColors.monoFontFamily,
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
