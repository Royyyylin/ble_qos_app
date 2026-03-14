import 'package:flutter/material.dart';

import '../../core/ble/ble_models.dart';
import '../../core/domain/connection_mode.dart';

/// List tile for a discovered BLE device.
class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.device, required this.onTap});

  final ScannedDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGw = device.mode == ConnectionMode.gwAggregate;
    return ListTile(
      leading: Icon(
        isGw ? Icons.router : Icons.sensors,
        color: isGw ? Colors.indigo : Colors.teal,
      ),
      title: Text(device.name.isEmpty ? '(unknown)' : device.name),
      subtitle: Text(isGw ? 'Gateway' : 'End Device'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${device.rssi} dBm',
              style: TextStyle(
                color: device.rssi > -60 ? Colors.green : Colors.orange,
              )),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
