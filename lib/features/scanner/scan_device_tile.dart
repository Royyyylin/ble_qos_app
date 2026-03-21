import 'package:flutter/material.dart';

import '../../core/ble/ble_models.dart';
import '../../core/theme/app_colors.dart';

/// Device card in scanner list — spec §4.
/// Shows name, RSSI, zone badge, status indicator.
class ScanDeviceTile extends StatelessWidget {
  const ScanDeviceTile({super.key, required this.device, required this.onTap});

  final ScannedDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${device.displayName}, ${device.roleLabel}, ${device.smoothedRssi.round()} dBm, ${device.status.name}',
      hint: 'Double tap to connect',
      button: true,
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _rssiWidget(),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          onTap: onTap,
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
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}
