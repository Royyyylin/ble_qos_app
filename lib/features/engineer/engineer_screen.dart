import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ble/ble_connector.dart';
import '../../core/ble/ble_gatt.dart';
import '../../core/domain/unlock_session.dart';
import '../../core/gatt/gatt_structs.dart';
import '../../core/gatt/gatt_uuids.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/metrics_provider.dart';
import '../../core/providers/role_provider.dart';
import '../../core/domain/role_policy.dart';
import '../../widgets/zone_indicator.dart';
import '../../widgets/metric_card.dart';

/// Engineer screen — diagnostics, CTRL, GW_CFG, PING, EVT raw, PIN management.
class EngineerScreen extends ConsumerStatefulWidget {
  const EngineerScreen({super.key});

  @override
  ConsumerState<EngineerScreen> createState() => _EngineerScreenState();
}

class _EngineerScreenState extends ConsumerState<EngineerScreen> {
  final _pinController = TextEditingController();
  String _statusMessage = '';
  bool _busy = false;
  QosCtrl? _lastCtrl;

  BleGatt get _gatt => BleGatt(ref.read(bleConnectorProvider));

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(unlockSessionProvider);
    final statusAsync = ref.watch(statusStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engineer'),
        actions: [
          if (session.isUnlocked)
            Chip(
              label: Text('Unlocked'),
              backgroundColor: Colors.green.withValues(alpha: 0.2),
            )
          else
            Chip(
              label: Text('Locked'),
              backgroundColor: Colors.red.withValues(alpha: 0.2),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ENG_UNLOCK
          _buildUnlockCard(session),
          const SizedBox(height: 16),

          // Diagnostics
          if (session.isUnlocked) ...[
            statusAsync.when(
              data: (status) => _buildDiagnostics(status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // CTRL reader
            _buildCtrlCard(),
            const SizedBox(height: 16),

            // GW_CFG editor
            _buildGwCfgCard(),
            const SizedBox(height: 16),

            // PING tool
            _buildPingCard(),
            const SizedBox(height: 16),

            // CMD console
            _buildCmdCard(),
            const SizedBox(height: 16),

            // PIN management
            _buildPinCard(),
          ],

          if (_statusMessage.isNotEmpty)
            Card(
              color: _statusMessage.startsWith('Error')
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_statusMessage),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnlockCard(UnlockSession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Engineer Unlock', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (4-16 digits)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: _busy ? null : _unlock,
                  child: const Text('Unlock'),
                ),
                const SizedBox(width: 8),
                if (session.isUnlocked)
                  OutlinedButton(
                    onPressed: () => session.refresh(),
                    child: const Text('Refresh 60s'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnostics(QosStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Diagnostics', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ZoneIndicator(zone: status.zone),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricCard(label: 'RSSI', value: '${status.rssi}', unit: 'dBm'),
                MetricCard(label: 'PDR', value: '${status.pdr}', unit: '%'),
                MetricCard(label: 'PHY', value: _phyName(status.phy)),
                MetricCard(label: 'TX', value: '${status.txPower}', unit: 'dBm'),
                MetricCard(label: 'Interval', value: '${status.interval}'),
                MetricCard(label: 'Latency', value: '${status.latency}', unit: 'ms'),
                MetricCard(label: 'Jitter', value: '${status.jitter}', unit: 'ms'),
                MetricCard(label: 'TP', value: '${status.tp}', unit: 'B/s'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtrlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CTRL (read-only in ED Direct)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _readCtrl,
              child: const Text('Read CTRL'),
            ),
            if (_lastCtrl != null) ...[
              const SizedBox(height: 8),
              Text('Profile: ${_lastCtrl!.profile} | PHY: ${_phyName(_lastCtrl!.phy)} | TX: ${_lastCtrl!.txPower}'),
              Text('Interval: ${_lastCtrl!.interval} | Credits: A=${_lastCtrl!.creditAlarm} C=${_lastCtrl!.creditCtrl} R=${_lastCtrl!.creditRs485}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGwCfgCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GW_CFG', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _readGwCfg,
                  child: const Text('Read'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _writeDefaultGwCfg,
                  child: const Text('Write Default'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PING / RTT', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('PING is GW-exclusive. Not available in ED Direct mode.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCmdCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CMD Console', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _busy ? null : _cmdReboot,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
              ),
              child: const Text('CMD 0x01: Reboot'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PIN Management', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _setNewPin,
              child: const Text('Set New PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    if (ref.read(connectedDeviceProvider) == null) return;
    setState(() => _busy = true);
    try {
      final pin = _pinController.text;
      await _gatt.write(GattUuids.engUnlock, utf8.encode(pin));
      ref.read(unlockSessionProvider).unlock(
            onExpired: () {
              ref.read(appRoleProvider.notifier).state = AppRole.patrol;
              if (mounted) setState(() => _statusMessage = 'Engineer session expired');
            },
          );
      ref.read(appRoleProvider.notifier).state = AppRole.engineer;
      setState(() => _statusMessage = 'Unlocked for 60s');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _readCtrl() async {
    if (ref.read(connectedDeviceProvider) == null) return;
    try {
      final data = await _gatt.read(GattUuids.ctrl);
      if (data.length == QosCtrl.size) {
        setState(() => _lastCtrl = QosCtrl.fromBytes(data));
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error reading CTRL: $e');
    }
  }

  Future<void> _readGwCfg() async {
    if (ref.read(connectedDeviceProvider) == null) return;
    try {
      final data = await _gatt.read(GattUuids.gwCfg);
      if (data.length == QosGwCfgV2.size) {
        final cfg = QosGwCfgV2.fromBytes(data);
        setState(() =>
            _statusMessage = 'GW_CFG: ver=${cfg.ver} tp=${cfg.tpMode} log=${cfg.log} '
                'A=${cfg.creditAlarm} C=${cfg.creditCtrl} R=${cfg.creditRs485}');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    }
  }

  Future<void> _writeDefaultGwCfg() async {
    if (ref.read(connectedDeviceProvider) == null) return;
    setState(() => _busy = true);
    try {
      final cfg = QosGwCfgV2(
        ver: 2, tpMode: 0, log: 1, flags: 0,
        creditAlarm: 5, creditCtrl: 3, creditRs485: 5, reserved: 0,
      );
      await _gatt.write(GattUuids.gwCfg, cfg.toBytes().toList());
      setState(() => _statusMessage = 'GW_CFG default written');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _cmdReboot() async {
    if (ref.read(connectedDeviceProvider) == null) return;
    setState(() => _busy = true);
    try {
      await _gatt.write(GattUuids.cmd, [0x01]);
      setState(() => _statusMessage = 'Reboot command sent. Device will disconnect.');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _setNewPin() async {
    if (ref.read(connectedDeviceProvider) == null) return;
    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Set New PIN'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '4-16 digits'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    if (newPin == null || newPin.length < 4 || newPin.length > 16) return;
    setState(() => _busy = true);
    try {
      await _gatt.write(GattUuids.engPinSet, utf8.encode(newPin));
      setState(() => _statusMessage = 'New PIN set');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  String _phyName(int p) => switch (p) { 1 => '1M', 2 => '2M', 4 => 'Coded S8', 5 => 'Coded S2', _ => '?' };
}
