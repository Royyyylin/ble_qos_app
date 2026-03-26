import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/ble/ble_connector.dart';
import '../../core/ble/ble_gatt.dart';
import '../../core/ble/ble_models.dart';
import '../../core/gatt/gatt_uuids.dart';
import '../../core/identity/device_identity_service.dart';
import '../../core/theme/app_colors.dart';

/// Max alias length in bytes (UTF-8). Matches firmware DEVICE_ALIAS characteristic size.
const _maxAliasBytes = 20;

/// Show rename dialog for a device. Returns the new alias if confirmed, null if cancelled.
Future<String?> showRenameDialog({
  required BuildContext context,
  required ScannedDevice device,
  required DeviceIdentityService identityService,
  required BleConnector connector,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _RenameDialog(
      device: device,
      identityService: identityService,
      connector: connector,
    ),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({
    required this.device,
    required this.identityService,
    required this.connector,
  });

  final ScannedDevice device;
  final DeviceIdentityService identityService;
  final BleConnector connector;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.device.alias ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _utf8ByteLength(String s) => utf8.encode(s).length;

  Future<void> _save() async {
    final alias = _controller.text.trim();

    // Validate UTF-8 byte length
    if (alias.isNotEmpty && _utf8ByteLength(alias) > _maxAliasBytes) {
      setState(() => _error = 'Alias too long (max $_maxAliasBytes bytes)');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Write to GATT if connected
      if (widget.connector.state == BleConnectionState.connected) {
        final gatt = BleGatt(widget.connector);
        await gatt.write(GattUuids.deviceAlias, utf8.encode(alias));
      }

      // Update local DB cache
      await widget.identityService.setAlias(
        widget.device.id,
        alias.isEmpty ? null : alias,
      );

      if (mounted) Navigator.of(context).pop(alias.isEmpty ? null : alias);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Write failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final byteLen = _utf8ByteLength(_controller.text.trim());

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Rename Device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advertising name',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            widget.device.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: 'Alias',
              hintText: 'e.g. 3F-會議室-GW',
              counterText: '$byteLen/$_maxAliasBytes bytes',
              errorText: _error,
              filled: true,
              fillColor: AppColors.surfaceVar,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
