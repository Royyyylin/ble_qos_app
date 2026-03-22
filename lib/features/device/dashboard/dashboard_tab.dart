import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/domain/health_threshold.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Metric definition with health judgment.
typedef _MetricDef = ({
  String label,
  String unit,
  String Function(QosStatus s) valueOf,
  HealthLevel Function(QosStatus s)? health,
});

/// Dashboard tab — telemetry metrics with Pass/Fail color coding.
/// Thresholds: RSSI>-65/PDR>95%/Lat<20ms/Jit<5ms (APP-side judgment).
class DashboardTab extends ConsumerWidget {
  final String deviceId;

  const DashboardTab({super.key, required this.deviceId});

  static final List<_MetricDef> _metrics = [
    (
      label: 'RSSI',
      unit: 'dBm',
      valueOf: (s) => '${s.rssi}',
      health: (s) => HealthThreshold.rssi(s.rssi),
    ),
    (
      label: 'PDR',
      unit: '%',
      valueOf: (s) => '${s.pdr}',
      health: (s) => HealthThreshold.pdr(s.pdr),
    ),
    (
      label: 'Latency',
      unit: 'ms',
      valueOf: (s) => '${s.latency}',
      health: (s) => HealthThreshold.latency(s.latency),
    ),
    (
      label: 'Jitter',
      unit: 'ms',
      valueOf: (s) => '${s.jitter}',
      health: (s) => HealthThreshold.jitter(s.jitter),
    ),
    (
      label: 'PHY',
      unit: '',
      valueOf: (s) => '${s.phy}',
      health: null, // config value, no threshold
    ),
    (
      label: 'TX Power',
      unit: 'dBm',
      valueOf: (s) => '${s.txPower}',
      health: null,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(statusStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Telemetry', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: statusAsync.when(
              loading: () => _buildGrid(null),
              error: (err, _) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (status) => _buildGrid(status),
            ),
          ),
        ],
      ),
    );
  }

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
            health: status != null && m.health != null
                ? m.health!(status)
                : HealthLevel.unknown,
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final HealthLevel health;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final color = HealthThreshold.colorFor(health);
    final semanticsLabel =
        unit.isNotEmpty ? '$label: $value $unit' : '$label: $value';

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
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
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
