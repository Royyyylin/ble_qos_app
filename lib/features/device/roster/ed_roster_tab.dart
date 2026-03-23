import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';

import '../../../core/gatt/gatt_structs.dart';
import '../../../core/providers/ed_roster_provider.dart';
import '../../../core/providers/metrics_provider.dart';
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

/// ED Roster tab — shows EDs from two sources:
/// 1. ROSTER_LIST GATT read (firmware roster slots with state)
/// 2. Scan results + GW indexed STATUS notify (live QoS metrics)
class EdRosterTab extends ConsumerWidget {
  final String deviceId;

  const EdRosterTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterListProvider);
    final scanRoster = ref.watch(edRosterProvider);

    return rosterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildScanOnlyRoster(scanRoster),
      data: (rosterEntries) {
        final nonEmpty = rosterEntries.where((e) => !e.isEmpty).toList();
        if (nonEmpty.isEmpty && scanRoster.isEmpty) {
          return _buildEmptyState();
        }
        return _buildCombinedRoster(context, nonEmpty, scanRoster, ref);
      },
    );
  }

  Widget _buildEmptyState() {
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
            'EDs will appear here once discovered via scanning or added to roster',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOnlyRoster(List<EdRosterEntry> scanRoster) {
    if (scanRoster.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scanRoster.length,
      itemBuilder: (_, index) => _ScanEdTile(entry: scanRoster[index]),
    );
  }

  Widget _buildCombinedRoster(
    BuildContext context,
    List<RosterEntry> rosterEntries,
    List<EdRosterEntry> scanRoster,
    WidgetRef ref,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // GATT Roster section
        if (rosterEntries.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Firmware Roster (${rosterEntries.length} slots)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh roster',
                  onPressed: () => ref.invalidate(rosterListProvider),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          for (final entry in rosterEntries)
            _RosterSlotTile(
              entry: entry,
              onRemove: () => _removeFromRoster(context, ref, entry),
            ),
          const SizedBox(height: 16),
        ],
        // Scan-based section
        if (scanRoster.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Discovered EDs (${scanRoster.length})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final entry in scanRoster)
            _ScanEdTile(
              entry: entry,
              onAddToRoster: entry.device.mac != null
                  ? () => _addToRoster(context, ref, entry.device.mac!)
                  : null,
            ),
        ],
      ],
    );
  }

  Future<void> _addToRoster(BuildContext context, WidgetRef ref, String macAddress) async {
    try {
      final cmdService = ref.read(cmdV2ServiceProvider);
      final pin = ref.read(authSessionProvider).lastPin;
      final result = await cmdService.rosterAdd(macAddress, pin: pin);
      if (!context.mounted) return;
      if (result != null && result.isSuccess) {
        ref.invalidate(rosterListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to roster')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add failed: ${result?.status ?? "timeout"}')),
        );
      }
    } catch (e) {
      debugPrint('[ROSTER] add failed: $e');
    }
  }

  Future<void> _removeFromRoster(BuildContext context, WidgetRef ref, RosterEntry entry) async {
    // Confirmation dialog for dangerous operation — spec §5
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Roster'),
        content: Text('Remove ${entry.address} (Slot ${entry.logicalSlot})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final cmdService = ref.read(cmdV2ServiceProvider);
      final pin = ref.read(authSessionProvider).lastPin;
      final result = await cmdService.rosterRemove(entry.logicalSlot, pin: pin);
      if (!context.mounted) return;
      if (result != null && result.isSuccess) {
        ref.invalidate(rosterListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from roster')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove failed: ${result?.status ?? "timeout"}')),
        );
      }
    } catch (e) {
      debugPrint('[ROSTER] remove failed: $e');
    }
  }
}

/// Tile for GATT ROSTER_LIST entries.
class _RosterSlotTile extends StatelessWidget {
  final RosterEntry entry;
  final VoidCallback? onRemove;

  const _RosterSlotTile({required this.entry, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isOnline = entry.isOnline;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isOnline ? Icons.link : Icons.link_off,
          color: isOnline ? AppColors.success : AppColors.stale,
          size: 20,
        ),
        title: Text(
          entry.address,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: AppColors.monoFontFamily,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Slot ${entry.logicalSlot} · ${entry.stateLabel}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stateBadge(entry),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.error,
                tooltip: 'Remove from roster',
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stateBadge(RosterEntry entry) {
    final (color, label) = switch (entry.state) {
      RosterSlotState.online => (AppColors.success, 'Online'),
      RosterSlotState.registered => (AppColors.warning, 'Registered'),
      _ => (AppColors.stale, 'Empty'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Tile for scan-discovered EDs (existing behavior).
class _ScanEdTile extends StatelessWidget {
  final EdRosterEntry entry;
  final VoidCallback? onAddToRoster;

  const _ScanEdTile({required this.entry, this.onAddToRoster});

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
            if (onAddToRoster != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.primary,
                tooltip: 'Add to roster',
                onPressed: onAddToRoster,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
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
