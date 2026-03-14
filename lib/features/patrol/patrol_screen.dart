import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/alarm_model.dart';
import '../../core/gatt/gatt_structs.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/metrics_provider.dart';
import '../../widgets/zone_indicator.dart';

/// Alarm history provider (in-memory).
final alarmHistoryProvider = Provider<AlarmHistory>((ref) => AlarmHistory());

/// Patrol screen — inspection checklist, abnormal nodes, alarm history.
class PatrolScreen extends ConsumerWidget {
  const PatrolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(connectedDeviceProvider);
    final statusAsync = ref.watch(statusStreamProvider);
    final evtAsync = ref.watch(evtStreamProvider);
    final alarmHistory = ref.watch(alarmHistoryProvider);

    // Accumulate alarm events
    evtAsync.whenData((evt) => alarmHistory.add(evt));

    return Scaffold(
      appBar: AppBar(title: Text('Patrol — ${device?.name ?? ""}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status summary
          statusAsync.when(
            data: (status) => _StatusSummaryCard(status: status),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(child: ListTile(title: Text('Error: $e'))),
          ),
          const SizedBox(height: 16),

          // Alarm history
          Row(
            children: [
              Text('Alarms', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (alarmHistory.unacknowledgedCount > 0)
                Badge(
                  label: Text('${alarmHistory.unacknowledgedCount}'),
                  child: const Icon(Icons.notifications_active),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => alarmHistory.acknowledgeAll(),
                child: const Text('ACK All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (alarmHistory.entries.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No alarms yet')),
              ),
            )
          else
            ...alarmHistory.entries.take(50).toList().asMap().entries.map(
                  (entry) => _AlarmTile(
                    index: entry.key,
                    alarm: entry.value,
                    onAck: () => alarmHistory.acknowledge(entry.key),
                    onNote: (note) => alarmHistory.addNote(entry.key, note),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({required this.status});
  final QosStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ZoneIndicator(zone: status.zone),
                const SizedBox(width: 12),
                Text('RSSI: ${status.rssi} dBm'),
                const Spacer(),
                Text('PDR: ${status.pdr}%'),
              ],
            ),
            const SizedBox(height: 8),
            Text('PHY: ${_phyName(status.phy)} | TX: ${status.txPower} dBm | TP: ${status.tp} B/s'),
          ],
        ),
      ),
    );
  }

  String _phyName(int p) => switch (p) { 1 => '1M', 2 => '2M', 4 => 'Coded S8', 5 => 'Coded S2', _ => '?' };
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.index,
    required this.alarm,
    required this.onAck,
    required this.onNote,
  });

  final int index;
  final AlarmEntry alarm;
  final VoidCallback onAck;
  final void Function(String) onNote;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: alarm.isAlarm && !alarm.acknowledged
          ? Colors.red.withValues(alpha: 0.05)
          : null,
      child: ListTile(
        leading: Icon(
          alarm.isAlarm ? Icons.warning : Icons.info,
          color: alarm.isAlarm ? Colors.red : Colors.blue,
        ),
        title: Text(
          '${alarm.isAlarm ? "ALARM" : "INFO"} id=${alarm.evt.id} '
          'v0=${alarm.evt.v0} v1=${alarm.evt.v1}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('seq=${alarm.evt.seq} | ${_timeAgo(alarm.timestamp)}'),
            if (alarm.note != null) Text('Note: ${alarm.note}'),
          ],
        ),
        trailing: alarm.acknowledged
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(icon: const Icon(Icons.check), onPressed: onAck),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}
