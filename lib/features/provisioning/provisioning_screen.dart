import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Provisioning flow — spec §9.
/// Role selector (GW/ED/CC), network_id input, device name,
/// ROLE write button with reboot warning. Engineer-only.
class ProvisioningScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const ProvisioningScreen({super.key, required this.deviceId});

  @override
  ConsumerState<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends ConsumerState<ProvisioningScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'Gateway';
  final _networkIdController = TextEditingController();
  final _deviceNameController = TextEditingController();

  static const _roleOptions = ['Gateway', 'End Device', 'Central Controller'];

  @override
  void dispose() {
    _networkIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provisioning')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Device ID display
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        widget.deviceId,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Role selector
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: _roleOptions.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Network ID input
              TextFormField(
                controller: _networkIdController,
                decoration: const InputDecoration(
                  labelText: 'Network ID',
                  hintText: 'Enter network ID (0-65535)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Network ID is required';
                  }
                  final id = int.tryParse(value);
                  if (id == null || id < 0 || id > 65535) {
                    return 'Must be 0-65535';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Device name input
              TextFormField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'Enter friendly name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Device name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Reboot warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withAlpha(76)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Writing ROLE will trigger a device reboot.',
                        style: TextStyle(color: AppColors.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Write ROLE button
              ElevatedButton(
                onPressed: _onWriteRole,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Write ROLE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onWriteRole() {
    if (!_formKey.currentState!.validate()) return;

    // Permission gate: ROLE requires engineer role (spec §3.2)
    final session = ref.read(authSessionProvider);
    final role = session.currentRole;
    if (!PermissionGuard.canWrite(role, GattAction.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied: engineer role required for ROLE write')),
      );
      return;
    }

    // Show confirmation dialog before writing ROLE
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Provisioning'),
        content: Text(
          'Write role "$_selectedRole" with network ID ${_networkIdController.text} '
          'to device ${widget.deviceId}?\n\nThe device will reboot.',
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
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        try {
          final roleValue = ManufacturerData.roleFromString(_selectedRole);
          final connector = ref.read(bleConnectorProvider);
          final gatt = BleGatt(connector);
          await gatt.write(GattUuids.role, [roleValue]);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ROLE write sent — device will reboot')),
          );
          // Navigate back after short delay for reboot
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.of(context).pop();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ROLE write failed: $e')),
          );
        }
      }
    });
  }
}
