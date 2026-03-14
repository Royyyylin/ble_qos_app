import 'package:flutter/material.dart';

import '../core/ble/ble_models.dart';

/// Top banner showing BLE connection state.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.state, this.deviceName});

  final BleConnectionState state;
  final String? deviceName;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (state) {
      BleConnectionState.disconnected => (Colors.red, 'Disconnected'),
      BleConnectionState.connecting => (Colors.orange, 'Connecting...'),
      BleConnectionState.handshaking => (Colors.amber, 'Handshaking...'),
      BleConnectionState.connected => (Colors.green, deviceName ?? 'Connected'),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.bluetooth, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
