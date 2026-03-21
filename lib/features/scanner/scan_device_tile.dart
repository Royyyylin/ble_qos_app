import 'package:flutter/material.dart';

import '../../core/ble/ble_models.dart';
import '../../core/theme/app_colors.dart';

/// Device card in scanner list — spec §4.
/// Shows name, RSSI, zone badge, status indicator.
/// Explicit Connect button — tapping tile body does NOT auto-connect.
class ScanDeviceTile extends StatelessWidget {
  const ScanDeviceTile({
    super.key,
    required this.device,
    required this.onConnect,
  });

  final ScannedDevice device;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${device.displayName}, ${device.roleLabel}, ${device.smoothedRssi.round()} dBm, ${device.status.name}',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _statusIndicator(),
          title: Text(
            device.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${device.roleLabel} ${device.networkId != null ? "| Net ${device.networkId}" : ""}',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _rssiWidget(),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Connect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator() {
    final (icon, color) = switch (device.status) {
      DeviceStatus.online => (Icons.circle, AppColors.success),
      DeviceStatus.stale => (Icons.circle, AppColors.warning),
      DeviceStatus.offline => (Icons.circle_outlined, AppColors.stale),
    };
    return Icon(icon, size: 12, color: color);
  }

  Widget _rssiWidget() {
    final rssi = device.smoothedRssi.round();
    final color = rssi > -60
        ? AppColors.success
        : rssi > -80
            ? AppColors.warning
            : AppColors.error;
    return Text(
      '$rssi dBm',
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFamily: AppColors.monoFontFamily,
      ),
    );
  }
}
