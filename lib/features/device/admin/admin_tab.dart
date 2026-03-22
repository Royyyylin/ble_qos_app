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
          // GW_CFG Editor
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('GW_CFG Editor'),
              subtitle: const Text('Edit gateway configuration'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showGwCfgEditor(context, ref),
            ),
          ),
          const SizedBox(height: 8),
          // PIN Management
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key, color: AppColors.secondary),
              title: const Text('PIN Management'),
              subtitle: const Text('Set engineer PIN'),
              trailing: const Icon(Icons.chevron_right),
              enabled: isEngineer,
              onTap: isEngineer ? () => _showPinSetDialog(context, ref) : null,
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

    if (confirmed != true || !context.mounted) {
      pinController.dispose();
      return;
    }

    final pin = pinController.text;
    pinController.dispose();
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

    if (writeType == null || writeValue == null || !context.mounted) {
      return;
    }

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

  /// GW_CFG Editor: read current config → form → write back.
  Future<void> _showGwCfgEditor(BuildContext context, WidgetRef ref) async {
    final gatt = _gatt(ref);

    // Read current GW_CFG
    QosGwCfgV2? current;
    try {
      final data = await gatt.read(GattUuids.gwCfg);
      if (data.length >= QosGwCfgV2.size) {
        current = QosGwCfgV2.fromBytes(data);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Failed to read GW_CFG: $e');
      return;
    }

    if (!context.mounted) return;
    current ??= const QosGwCfgV2(
      ver: 2, tpMode: 1, log: 0, flags: 0,
      creditAlarm: 1, creditCtrl: 1, creditRs485: 1, reserved: 0,
    );

    final tpModeCtrl = TextEditingController(text: '${current.tpMode}');
    final logCtrl = TextEditingController(text: '${current.log}');
    final flagsCtrl = TextEditingController(text: '${current.flags}');
    final credACtrl = TextEditingController(text: '${current.creditAlarm}');
    final credCCtrl = TextEditingController(text: '${current.creditCtrl}');
    final credRCtrl = TextEditingController(text: '${current.creditRs485}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GW_CFG Editor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cfgField(tpModeCtrl, 'TP Mode', '0=STRESS, 1=PRODUCT'),
              _cfgField(logCtrl, 'Phone Log', '0=off, 1=on'),
              _cfgField(flagsCtrl, 'Flags', 'QOS_GWCFG_FLAG_DISABLE_* bits'),
              _cfgField(credACtrl, 'Credit Alarm (pps)', '0=disabled'),
              _cfgField(credCCtrl, 'Credit Ctrl (pps)', null),
              _cfgField(credRCtrl, 'Credit RS485 (pps)', null),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Write'),
          ),
        ],
      ),
    );

    final cfg = QosGwCfgV2(
      ver: 2,
      tpMode: int.tryParse(tpModeCtrl.text) ?? current.tpMode,
      log: int.tryParse(logCtrl.text) ?? current.log,
      flags: int.tryParse(flagsCtrl.text) ?? current.flags,
      creditAlarm: int.tryParse(credACtrl.text) ?? current.creditAlarm,
      creditCtrl: int.tryParse(credCCtrl.text) ?? current.creditCtrl,
      creditRs485: int.tryParse(credRCtrl.text) ?? current.creditRs485,
      reserved: 0,
    );

    for (final c in [tpModeCtrl, logCtrl, flagsCtrl, credACtrl, credCCtrl, credRCtrl]) {
      c.dispose();
    }

    if (confirmed != true || !context.mounted) return;

    try {
      await gatt.write(GattUuids.gwCfg, cfg.toBytes());
      if (!context.mounted) return;
      _showSnackBar(context, 'GW_CFG written successfully');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'GW_CFG write failed: $e');
    }
  }

  Widget _cfgField(TextEditingController ctrl, String label, String? hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  /// ENG_PIN_SET: write new PIN to vendor UUID (requires ENGINEER mode).
  Future<void> _showPinSetDialog(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (session.currentRole != AuthRole.engineer) {
      _showSnackBar(context, 'Engineer mode required to set PIN');
      return;
    }

    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Engineer PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                hintText: '4-16 digit PIN',
                border: OutlineInputBorder(),
              ),
              maxLength: 16,
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
              maxLength: 16,
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );

    final pin = pinController.text;
    final confirm = confirmController.text;
    pinController.dispose();
    confirmController.dispose();

    if (confirmed != true || !context.mounted) return;

    if (pin.length < 4 || pin.length > 16) {
      _showSnackBar(context, 'PIN must be 4-16 digits');
      return;
    }
    if (pin != confirm) {
      _showSnackBar(context, 'PINs do not match');
      return;
    }

    try {
      await _gatt(ref).write(GattUuids.engPinSet, pin.codeUnits);
      if (!context.mounted) return;
      _showSnackBar(context, 'Engineer PIN updated');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'PIN set failed: $e');
    }
  }
}
