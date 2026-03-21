import 'package:flutter/material.dart';

import '../core/ble/ble_models.dart';

/// AppBar indicator showing real-time BleConnectionState.
/// Shows spinner for connecting/handshaking, check for connected, error icon for error/disconnected.
class ConnectionStateIndicator extends StatelessWidget {
  const ConnectionStateIndicator({super.key, required this.state, this.onRetry});

  final BleConnectionState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      BleConnectionState.connecting || BleConnectionState.handshaking => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange,
          ),
        ),
      ),
      BleConnectionState.connected => const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.bluetooth_connected, color: Colors.green, size: 20),
      ),
      BleConnectionState.error || BleConnectionState.disconnected => GestureDetector(
        onTap: onRetry,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.bluetooth_disabled, color: Colors.red, size: 20),
        ),
      ),
    };
  }
}
