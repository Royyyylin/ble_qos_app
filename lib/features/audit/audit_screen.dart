import 'package:flutter/material.dart';

/// Audit log view — spec §12. Stub for GoRouter integration.
class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: const Center(child: Text('Audit log entries')),
    );
  }
}
