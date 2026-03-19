import 'package:flutter/material.dart';

/// Capability-driven device screen — spec §5. Stub for GoRouter integration.
class DeviceScreen extends StatelessWidget {
  final String deviceId;

  const DeviceScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Device $deviceId')),
      body: Center(child: Text('Device detail for $deviceId')),
    );
  }
}
