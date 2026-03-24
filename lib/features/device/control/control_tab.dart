import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// QoS profile definitions matching firmware enum.
const _profiles = [
  (value: 0, label: 'FAST', desc: 'Low latency, high power'),
  (value: 1, label: 'BALANCED', desc: 'Default trade-off'),
  (value: 2, label: 'ROBUST', desc: 'High reliability, higher latency'),
];

/// Control tab — QoS profile selector and CTRL write (spec §6).
/// Permission-gated by PermissionGuard.canWrite().
class ControlTab extends ConsumerStatefulWidget {
  final String deviceId;

  const ControlTab({super.key, required this.deviceId});

  @override
  ConsumerState<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends ConsumerState<ControlTab> {
  int _selectedProfile = 0;
  bool _writing = false;

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _writeCtrl() async {
    final session = ref.read(authSessionProvider);
    final role = session.currentRole;

    if (!PermissionGuard.canWrite(role, GattAction.ctrl)) {
      _showSnackBar('Permission denied: maintenance role required');
      return;
    }

    setState(() => _writing = true);

    // Read current device state to preserve phy/txPower/interval — only change profile
    final currentStatus = ref.read(statusStreamProvider).valueOrNull;
    final ctrl = QosCtrl(
      profile: _selectedProfile,
      phy: currentStatus?.phy ?? 1,
      txPower: currentStatus?.txPower ?? 0,
      creditAlarm: 0,
      creditCtrl: 0,
      creditRs485: 0,
      interval: currentStatus?.interval ?? 24,
    );

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      await gatt.write(GattUuids.ctrl, ctrl.toBytes());
      _showSnackBar(
          'Profile ${_profiles[_selectedProfile].label} written');
    } catch (e) {
      _showSnackBar('CTRL write failed: $e');
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QoS Control', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Profile selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QoS Profile',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...List.generate(_profiles.length, (i) {
                    final p = _profiles[i];
                    return RadioListTile<int>(
                      value: p.value,
                      groupValue: _selectedProfile,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedProfile = v);
                      },
                      title: Text(p.label),
                      subtitle: Text(p.desc,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      activeColor: AppColors.primary,
                      dense: true,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Write button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _writing ? null : _writeCtrl,
              icon: _writing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_writing ? 'Writing...' : 'Apply Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ROLE write — maintenance-safe config surface (spec §5 C2)
          if (PermissionGuard.canWrite(
              ref.watch(authSessionProvider).currentRole, GattAction.role))
            _RoleSelector(onWrite: _writeRole),
        ],
      ),
    );
  }

  Future<void> _writeRole(int roleValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm ROLE Write'),
        content: const Text('Writing ROLE will reboot the device.\nThe BLE connection will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Write & Reboot'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      await gatt.write(GattUuids.role, [roleValue]);
      if (mounted) _showSnackBar('ROLE written — device will reboot');
    } catch (e) {
      if (mounted) _showSnackBar('ROLE write failed: $e');
    }
  }
}

class _RoleSelector extends StatefulWidget {
  final Future<void> Function(int roleValue) onWrite;
  const _RoleSelector({required this.onWrite});

  @override
  State<_RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<_RoleSelector> {
  String _selected = 'Gateway';

  static const _roles = [
    (value: ManufacturerData.roleGateway, label: 'Gateway'),
    (value: ManufacturerData.roleEndDevice, label: 'End Device'),
    (value: ManufacturerData.roleCentralController, label: 'Central Controller'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Device Role', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Warning: writing ROLE triggers device reboot',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selected,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: _roles.map((r) => DropdownMenuItem(value: r.label, child: Text(r.label))).toList(),
              onChanged: (v) { if (v != null) setState(() => _selected = v); },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final role = _roles.firstWhere((r) => r.label == _selected);
                  widget.onWrite(role.value);
                },
                icon: const Icon(Icons.memory),
                label: const Text('Write Role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
