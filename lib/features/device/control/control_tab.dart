import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
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

    final ctrl = QosCtrl(
      profile: _selectedProfile,
      phy: 2,
      txPower: 0,
      interval: 80,
      creditAlarm: 0,
      creditCtrl: 0,
      creditRs485: 0,
      flags: 0,
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
        ],
      ),
    );
  }
}
