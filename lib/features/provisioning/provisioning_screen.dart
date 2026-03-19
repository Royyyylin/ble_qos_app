import 'package:flutter/material.dart';

/// Provisioning flow — spec §9. Stub for GoRouter integration.
class ProvisioningScreen extends StatelessWidget {
  final String deviceId;

  const ProvisioningScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provisioning')),
      body: Center(child: Text('Provision device $deviceId')),
    );
  }
}
