import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Control tab — QoS profile selector and CTRL write buttons (spec §6).
/// Permission-gated by PermissionGuard.canWrite().
class ControlTab extends ConsumerWidget {
  final String deviceId;

  const ControlTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QoS Control',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune, color: AppColors.primary),
              title: const Text('QoS Profile'),
              subtitle: const Text('Select active profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show profile selector
              },
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Write CTRL: send control command to device',
            hint: 'Double tap to write',
            button: true,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.send, color: AppColors.primary),
                title: const Text('Write CTRL'),
                subtitle: const Text('Send control command'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _writeCtrl(context, ref),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_ethernet, color: AppColors.primary),
              title: const Text('Gateway Config'),
              subtitle: const Text('Edit GW_CFG parameters'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show a [SnackBar] if the widget is still mounted.
  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// CTRL write flow: PermissionGuard check → QosCtrl.toBytes() → BleGatt.write()
  Future<void> _writeCtrl(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    final role = session.currentRole;

    // Permission gate: CTRL requires maintenance+ role
    if (!PermissionGuard.canWrite(role, GattAction.ctrl)) {
      _showSnackBar(context, 'Permission denied: maintenance role required for CTRL write');
      return;
    }

    // Build default CTRL payload (profile=FAST, phy=2M, tx=0)
    final ctrl = QosCtrl(
      profile: 0,
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
      _showSnackBar(context, 'CTRL written successfully');
    } catch (e) {
      _showSnackBar(context, 'CTRL write failed: $e');
    }
  }
}
