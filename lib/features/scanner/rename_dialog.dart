import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/ble/ble_models.dart';
import '../../core/identity/device_identity_service.dart';
import '../../core/theme/app_colors.dart';

/// Max alias length in bytes (UTF-8).
/// Central authority has no MTU limit; 32B ≈ 10 CJK chars, enough for site labels.
const _maxAliasBytes = 32;

/// Show rename dialog for a device. Returns the new alias if confirmed, null if cancelled.
/// Writes to local DB only (Central sync is a separate concern).
Future<String?> showRenameDialog({
  required BuildContext context,
  required ScannedDevice device,
  required DeviceIdentityService identityService,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _RenameDialog(
      device: device,
      identityService: identityService,
    ),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({
    required this.device,
    required this.identityService,
  });

  final ScannedDevice device;
  final DeviceIdentityService identityService;

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

    // Write to local DB (Central sync is a separate concern)
    await widget.identityService.setAlias(
      widget.device.id,
      alias.isEmpty ? null : alias,
    );

    if (mounted) Navigator.of(context).pop(alias.isEmpty ? null : alias);
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
            maxLength: 32,
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
