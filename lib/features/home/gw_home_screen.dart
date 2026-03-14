import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ble/ble_connector.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/metrics_provider.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/zone_indicator.dart';

/// GW Aggregate home screen — shows multi-ED overview via GW.
class GwHomeScreen extends ConsumerWidget {
  const GwHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(connectedDeviceProvider);
    final connector = ref.watch(bleConnectorProvider);
    final statusAsync = ref.watch(statusStreamProvider);
    final evtAsync = ref.watch(evtStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(device?.name ?? 'Gateway'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            connector.disconnect();
            ref.read(connectedDeviceProvider.notifier).disconnect();
            Navigator.of(context).pushReplacementNamed('/');
          },
        ),
      ),
      body: Column(
        children: [
          ConnectionBanner(
            state: connector.state,
            deviceName: device?.name,
          ),
          Expanded(
            child: statusAsync.when(
              data: (status) => _buildStatusView(context, status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          // Alarm summary
          evtAsync.when(
            data: (evt) => evt.isAlarm
                ? Container(
                    color: Colors.red.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('ALARM id=${evt.id} v0=${evt.v0} v1=${evt.v1}',
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Patrol'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStatusView(BuildContext context, dynamic status) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ZoneIndicator(zone: status.zone),
              const SizedBox(width: 12),
              Text('Profile: ${_profileName(status.profile)}',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricCard(label: 'RSSI', value: '${status.rssi}', unit: 'dBm'),
              MetricCard(label: 'PDR', value: '${status.pdr}', unit: '%'),
              MetricCard(label: 'PHY', value: _phyName(status.phy)),
              MetricCard(label: 'TX', value: '${status.txPower}', unit: 'dBm'),
              MetricCard(label: 'Interval', value: '${status.interval}', unit: 'units'),
              MetricCard(label: 'TP', value: '${status.tp}', unit: 'B/s'),
            ],
          ),
        ],
      ),
    );
  }

  String _profileName(int p) => switch (p) { 0 => 'FAST', 1 => 'BALANCED', 2 => 'ROBUST', _ => '?' };
  String _phyName(int p) => switch (p) { 1 => '1M', 2 => '2M', 4 => 'Coded S8', 5 => 'Coded S2', _ => '?' };
}
