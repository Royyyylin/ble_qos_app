import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/domain/health_threshold.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';
import 'package:ble_qos_app/data/tooltip_content.dart';
import 'package:ble_qos_app/widgets/info_tooltip.dart';

/// Metric definition with health judgment and tooltip.
typedef _MetricDef = ({
  String label,
  String unit,
  String Function(QosStatus s, QosMetricsV2? m) valueOf,
  HealthLevel Function(QosStatus s, QosMetricsV2? m)? health,
  ({String title, String body})? tooltip,
});

/// Whether a QosStatus represents "no data" (ED not in active QoS session).
/// Firmware returns all zeros when ED is not participating.
bool _isNoData(QosStatus s) =>
    s.rssi == 0 && s.pdr == 0 && s.latency == 0 && s.jitter == 0;

/// Dashboard tab — telemetry metrics with Pass/Fail color coding.
/// Thresholds: RSSI>-65/PDR>95%/Lat<20ms/Jit<5ms (APP-side judgment).
class DashboardTab extends ConsumerWidget {
  final String deviceId;

  const DashboardTab({super.key, required this.deviceId});

  static final List<_MetricDef> _metrics = [
    (
      label: 'RSSI',
      unit: 'dBm',
      valueOf: (s, _) => _isNoData(s) ? '--' : '${s.rssi}',
      health: (s, _) => _isNoData(s) ? HealthLevel.unknown : HealthThreshold.rssi(s.rssi),
      tooltip: TooltipContent.rssi,
    ),
    (
      label: 'PDR',
      unit: '%',
      valueOf: (s, _) => _isNoData(s) ? '--' : '${s.pdr}',
      health: (s, _) => _isNoData(s) ? HealthLevel.unknown : HealthThreshold.pdr(s.pdr),
      tooltip: TooltipContent.pdr,
    ),
    (
      label: 'Latency',
      unit: 'ms',
      valueOf: (s, _) => _isNoData(s) ? '--' : '${s.latency}',
      health: (s, _) => _isNoData(s) ? HealthLevel.unknown : HealthThreshold.latency(s.latency),
      tooltip: TooltipContent.latency,
    ),
    (
      label: 'Jitter',
      unit: 'ms',
      valueOf: (s, _) => _isNoData(s) ? '--' : '${s.jitter}',
      health: (s, _) => _isNoData(s) ? HealthLevel.unknown : HealthThreshold.jitter(s.jitter),
      tooltip: TooltipContent.jitter,
    ),
    (
      label: 'PHY',
      unit: '',
      valueOf: (s, _) => _isNoData(s) ? '--' : '${s.phy}',
      health: null,
      tooltip: TooltipContent.phy,
    ),
    (
      label: 'TX Power',
      unit: 'dBm',
      valueOf: (s, _) => _isNoData(s) ? '--' : '${s.txPower}',
      health: null,
      tooltip: TooltipContent.txPower,
    ),
    (
      label: 'Throughput',
      unit: 'B/s',
      valueOf: (_, m) => m == null ? '--' : '${m.tpBps}',
      health: null,
      tooltip: TooltipContent.throughput,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(statusStreamProvider);
    final metricsAsync = ref.watch(metricsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Telemetry', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: statusAsync.when(
              loading: () => _buildGrid(null, null),
              error: (err, _) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (status) => _buildGrid(
                status,
                metricsAsync.valueOrNull,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(QosStatus? status, QosMetricsV2? metrics) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final m in _metrics)
          _MetricCard(
            label: m.label,
            value: status != null ? m.valueOf(status, metrics) : '--',
            unit: m.unit,
            health: status != null && m.health != null
                ? m.health!(status, metrics)
                : HealthLevel.unknown,
            tooltip: m.tooltip,
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
  final ({String title, String body})? tooltip;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.health,
    this.tooltip,
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
              Row(
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  if (tooltip != null) ...[
                    const SizedBox(width: 4),
                    InfoTooltip(title: tooltip!.title, body: tooltip!.body),
                  ],
                ],
              ),
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
