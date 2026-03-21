import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/auth/auth_session.dart';
import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// ENG_UNLOCK PIN length per firmware spec.
const int engPinLength = 8;

/// Admin tab — engineer-only actions (spec §11).
/// ENG_UNLOCK, CMD reboot, MODE/ROLE write, GW_CFG editor, PIN management.
class AdminTab extends ConsumerWidget {
  final String deviceId;

  const AdminTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isEngineer = session.currentRole == AuthRole.engineer;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Engineer Admin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // ENG_UNLOCK
          Card(
            child: ListTile(
              leading: Icon(
                isEngineer ? Icons.lock_open : Icons.lock,
                color: isEngineer ? AppColors.success : AppColors.warning,
              ),
              title: const Text('ENG_UNLOCK'),
              subtitle: Text(isEngineer ? 'Engineer mode active' : 'Unlock engineer mode on device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: isEngineer ? null : () => _showEngUnlockDialog(context, ref),
            ),
          ),
          const SizedBox(height: 8),
          // CMD Reboot
          Card(
            child: ListTile(
              leading: const Icon(Icons.restart_alt, color: AppColors.error),
              title: const Text('CMD Reboot'),
              subtitle: const Text('Reboot device'),
              trailing: const Icon(Icons.chevron_right),
              enabled: isEngineer,
              onTap: isEngineer ? () => _showRebootConfirmation(context, ref) : null,
            ),
          ),
          const SizedBox(height: 8),
          // MODE / ROLE
          Card(
            child: ListTile(
              leading: const Icon(Icons.memory, color: AppColors.primary),
              title: const Text('MODE / ROLE'),
              subtitle: const Text('Change device mode or role'),
              trailing: const Icon(Icons.chevron_right),
              enabled: isEngineer,
              onTap: isEngineer ? () => _showModeRoleDialog(context, ref) : null,
            ),
          ),
          const SizedBox(height: 8),
          // GW_CFG Editor (existing TODO — not implemented in this task)
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('GW_CFG Editor'),
              subtitle: const Text('Edit gateway configuration'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
          const SizedBox(height: 8),
          // PIN Management (existing TODO — not implemented in this task)
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key, color: AppColors.secondary),
              title: const Text('PIN Management'),
              subtitle: const Text('Set engineer PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: PIN management
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Create a [BleGatt] instance from the current [BleConnector].
  BleGatt _gatt(WidgetRef ref) => BleGatt(ref.read(bleConnectorProvider));

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// ENG_UNLOCK flow: show PIN dialog → write ENG_UNLOCK characteristic → elevate AuthSession
  Future<void> _showEngUnlockDialog(BuildContext context, WidgetRef ref) async {
    final pinController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Engineer Unlock'),
        content: TextField(
          controller: pinController,
          decoration: const InputDecoration(
            labelText: 'Engineer PIN',
            hintText: 'Enter 8-character PIN',
            border: OutlineInputBorder(),
          ),
          maxLength: engPinLength,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final pin = pinController.text;
    if (pin.length != engPinLength) {
      _showSnackBar(context, 'PIN must be exactly $engPinLength characters');
      return;
    }

    try {
      // Write ASCII PIN bytes to ENG_UNLOCK characteristic
      await _gatt(ref).write(GattUuids.engUnlock, pin.codeUnits);
      // Success — elevate AuthSession to engineer
      final session = ref.read(authSessionProvider);
      session.elevate(AuthRole.engineer, onExpired: () {
        if (context.mounted) {
          _showSnackBar(context, 'Engineer session expired');
        }
      });
      if (!context.mounted) return;
      _showSnackBar(context, 'Engineer mode unlocked');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'ENG_UNLOCK failed: $e');
    }
  }

  /// CMD Reboot flow: confirmation dialog → write CMD 0x01 → handle disconnect
  Future<void> _showRebootConfirmation(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (!PermissionGuard.canWrite(session.currentRole, GattAction.cmdReboot)) {
      _showSnackBar(context, 'Permission denied: engineer role required');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reboot'),
        content: const Text(
          'This will reboot the device.\nThe BLE connection will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reboot'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await _gatt(ref).write(GattUuids.cmd, [CmdCode.reboot]);
      if (!context.mounted) return;
      _showSnackBar(context, 'Reboot command sent — device will disconnect');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Reboot failed: $e');
    }
  }

  /// MODE/ROLE write flow: dropdown selector → confirmation → GATT write
  Future<void> _showModeRoleDialog(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (!PermissionGuard.canWrite(session.currentRole, GattAction.mode)) {
      _showSnackBar(context, 'Permission denied: engineer role required');
      return;
    }

    String? writeType;
    int? writeValue;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String selectedType = 'MODE';
        String selectedRole = ManufacturerData.roleNames.first;
        final modeController = TextEditingController(text: '0');

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Write MODE / ROLE'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'MODE', label: Text('MODE')),
                    ButtonSegment(value: 'ROLE', label: Text('ROLE')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) => setDialogState(() => selectedType = s.first),
                ),
                const SizedBox(height: 16),
                if (selectedType == 'ROLE')
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: ManufacturerData.roleNames.map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedRole = v);
                    },
                  )
                else
                  TextFormField(
                    controller: modeController,
                    decoration: const InputDecoration(
                      labelText: 'Mode value (uint8)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 8),
                if (selectedType == 'ROLE')
                  const Text(
                    'Warning: ROLE write will trigger device reboot.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  writeType = selectedType;
                  if (selectedType == 'ROLE') {
                    writeValue = ManufacturerData.roleFromString(selectedRole);
                  } else {
                    writeValue = int.tryParse(modeController.text) ?? 0;
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Write'),
              ),
            ],
          ),
        );
      },
    );

    if (writeType == null || writeValue == null || !context.mounted) return;

    // Confirmation for ROLE write (triggers reboot)
    if (writeType == 'ROLE') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm ROLE Write'),
          content: Text(
            'Write ROLE value 0x${writeValue!.toRadixString(16)} '
            'to device $deviceId?\n\nThe device will reboot.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    try {
      final uuid = writeType == 'ROLE' ? GattUuids.role : GattUuids.mode;
      await _gatt(ref).write(uuid, [writeValue!]);
      if (!context.mounted) return;
      _showSnackBar(context, '$writeType written successfully');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, '$writeType write failed: $e');
    }
  }
}
