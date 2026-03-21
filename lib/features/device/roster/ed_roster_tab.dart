import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ble/ble_connector.dart';
import '../../../core/ble/ble_gatt.dart';
import '../../../core/gatt/gatt_cmd_service.dart';
import '../../../core/gatt/gatt_structs.dart';
import '../../../core/providers/ed_roster_provider.dart';
import '../../../core/providers/metrics_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Refresh ED_LIST after a short delay (give GW time to update).
Future<void> _refreshEdListDelayed(BleConnector connector, GwEdListNotifier notifier) async {
  await Future.delayed(const Duration(seconds: 2));
  await refreshGwEdList(connector, notifier);
}

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
/// Connect/Disconnect buttons send CMD 0x03/0x04 to the GW.
class EdRosterTab extends ConsumerStatefulWidget {
  final String deviceId;

  const EdRosterTab({super.key, required this.deviceId});

  @override
  ConsumerState<EdRosterTab> createState() => _EdRosterTabState();
}

class _EdRosterTabState extends ConsumerState<EdRosterTab> {
  /// Track which ED is currently being operated on (by device ID).
  String? _pendingDeviceId;
  StreamSubscription<QosEvtV1>? _evtSub;

  @override
  void dispose() {
    _evtSub?.cancel();
    super.dispose();
  }

  /// Listen for EVT INFO responses to CMD 0x03/0x04.
  void _listenForEvtResponse() {
    _evtSub?.cancel();
    final evtAsync = ref.read(evtStreamProvider);
    // EVT stream is already subscribed via provider; we watch for changes in build()
  }

  Future<void> _onConnect(EdRosterEntry entry) async {
    if (_pendingDeviceId != null) return;
    setState(() => _pendingDeviceId = entry.device.id);

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      final cmd = GattCmdService(gatt);
      await cmd.connectEd(entry.device.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecting ${entry.device.displayName}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CMD failed: $e')),
        );
      }
    } finally {
      // Clear pending after a delay to allow EVT response to arrive
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _pendingDeviceId = null);
      });
    }
  }

  Future<void> _onDisconnect(EdRosterEntry entry) async {
    if (_pendingDeviceId != null) return;
    setState(() => _pendingDeviceId = entry.device.id);

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      final cmd = GattCmdService(gatt);
      // Use edIndex from gwStatus if available, otherwise best-effort from roster index
      final edIdx = entry.gwStatus?.edIndex ?? 0;
      await cmd.disconnectEd(edIdx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnecting ${entry.device.displayName}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CMD failed: $e')),
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _pendingDeviceId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(edRosterProvider);

    // Watch EVT stream for CMD responses (shows SnackBar on success/fail)
    ref.listen<AsyncValue<QosEvtV1>>(evtStreamProvider, (_, next) {
      final evt = next.valueOrNull;
      if (evt == null || !evt.isAlarm) return; // only INFO type
      _handleEvtInfo(evt);
    });

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
        final isPending = _pendingDeviceId == entry.device.id;
        return _EdRosterTile(
          entry: entry,
          isPending: isPending,
          onConnect: () => _onConnect(entry),
          onDisconnect: () => _onDisconnect(entry),
        );
      },
    );
  }

  void _handleEvtInfo(QosEvtV1 evt) {
    final msg = switch (evt.id) {
      EvtInfoId.cmdConnectOk => 'ED #${evt.v0} connected',
      EvtInfoId.cmdConnectFail => 'Connect failed (error ${evt.v0})',
      EvtInfoId.cmdDisconnectOk => 'ED #${evt.v0} disconnected',
      EvtInfoId.cmdDisconnectFail => 'Disconnect failed (ED #${evt.v0})',
      _ => null,
    };
    if (msg != null && mounted) {
      setState(() => _pendingDeviceId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
      // Refresh ED_LIST after connect/disconnect success
      if (evt.id == EvtInfoId.cmdConnectOk || evt.id == EvtInfoId.cmdDisconnectOk) {
        final connector = ref.read(bleConnectorProvider);
        _refreshEdListDelayed(connector, ref.read(gwEdListProvider.notifier));
      }
    }
  }
}

class _EdRosterTile extends StatelessWidget {
  final EdRosterEntry entry;
  final bool isPending;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _EdRosterTile({
    required this.entry,
    required this.isPending,
    required this.onConnect,
    required this.onDisconnect,
  });

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
            _actionButton(connected),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(bool connected) {
    if (isPending) {
      return const SizedBox(
        width: 80,
        height: 32,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: connected ? onDisconnect : onConnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: connected ? AppColors.error : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(connected ? 'Disconnect' : 'Connect'),
      ),
    );
  }
}
