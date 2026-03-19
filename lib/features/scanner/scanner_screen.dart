import 'package:flutter/material.dart';

/// Fleet Overview Dashboard — spec §4. Stub for GoRouter integration.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Overview')),
      body: const Center(child: Text('Scanner / Fleet Dashboard')),
    );
  }
}
