import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ble/ble_gatt.dart';
import '../../core/domain/role_policy.dart';
import '../../core/gatt/gatt_uuids.dart';
import '../../core/providers/ble_provider.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/role_provider.dart';

/// Installer screen — ROLE setting, SET_MAX_ED, naming, install verification.
class InstallerScreen extends ConsumerStatefulWidget {
  const InstallerScreen({super.key});

  @override
  ConsumerState<InstallerScreen> createState() => _InstallerScreenState();
}

class _InstallerScreenState extends ConsumerState<InstallerScreen> {
  int _selectedRole = 1; // default: ED
  int _maxEd = 3;
  String _statusMessage = '';
  bool _busy = false;

  BleGatt get _gatt => BleGatt(ref.read(bleInstanceProvider));
  String? get _deviceId => ref.read(connectedDeviceProvider)?.id;

  @override
  Widget build(BuildContext context) {
    final appRole = ref.watch(appRoleProvider);
    final canWrite = appRole == AppRole.installer || appRole == AppRole.engineer;

    return Scaffold(
      appBar: AppBar(title: const Text('Installer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ROLE setting
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device Role', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Unprov')),
                      ButtonSegment(value: 1, label: Text('ED')),
                      ButtonSegment(value: 2, label: Text('GW')),
                      ButtonSegment(value: 3, label: Text('Repeater')),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: canWrite
                        ? (v) => setState(() => _selectedRole = v.first)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: canWrite && !_busy ? _writeRole : null,
                    child: const Text('Write ROLE (triggers reboot)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SET_MAX_ED
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Max ED Count', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxEd.toDouble(),
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '$_maxEd',
                          onChanged: canWrite
                              ? (v) => setState(() => _maxEd = v.round())
                              : null,
                        ),
                      ),
                      Text('$_maxEd'),
                    ],
                  ),
                  FilledButton(
                    onPressed: canWrite && !_busy ? _writeMaxEd : null,
                    child: const Text('SET_MAX_ED'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status message
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

  Future<void> _writeRole() async {
    if (_deviceId == null) return;
    setState(() => _busy = true);
    try {
      await _gatt.write(_deviceId!, GattUuids.role, [_selectedRole]);
      setState(() => _statusMessage = 'ROLE=$_selectedRole written. Device will reboot.');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _writeMaxEd() async {
    if (_deviceId == null) return;
    setState(() => _busy = true);
    try {
      // CMD 0x02 = SET_MAX_ED, payload = [0x02, maxEd]
      await _gatt.write(_deviceId!, GattUuids.cmd, [0x02, _maxEd]);
      setState(() => _statusMessage = 'SET_MAX_ED=$_maxEd sent.');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }
}
