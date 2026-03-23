import 'package:flutter/material.dart';

import '../core/error/ble_error.dart';
import '../core/theme/app_colors.dart';

/// Full-screen error state with classified error display — spec §4.
/// Shows icon + message + action based on BleErrorType.
class ConnectionErrorScreen extends StatelessWidget {
  const ConnectionErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.isRetryable = true,
    this.errorType,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isRetryable;
  final BleErrorType? errorType;

  IconData get _icon => switch (errorType) {
    BleErrorType.permissionDenied => Icons.lock,
    BleErrorType.bluetoothOff => Icons.bluetooth_disabled,
    BleErrorType.outOfRange => Icons.signal_wifi_off,
    BleErrorType.timeout => Icons.timer_off,
    _ => Icons.bluetooth_disabled,
  };

  Color get _iconColor => switch (errorType) {
    BleErrorType.permissionDenied => AppColors.warning,
    BleErrorType.bluetoothOff => AppColors.warning,
    _ => AppColors.error,
  };

  String get _actionLabel => switch (errorType) {
    BleErrorType.permissionDenied => 'Open Settings',
    BleErrorType.bluetoothOff => 'Enable Bluetooth',
    _ => 'Retry',
  };

  @override
  Widget build(BuildContext context) {
    final showRetry = (isRetryable || errorType?.isRetryable == true) && onRetry != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 64, color: _iconColor),
            const SizedBox(height: 16),
            Text(
              errorType?.userMessage ?? message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            if (message != (errorType?.userMessage ?? message)) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            if (showRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(_actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
