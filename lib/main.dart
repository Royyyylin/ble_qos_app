import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/device_list/device_list_screen.dart';
import 'features/home/ed_home_screen.dart';
import 'features/home/gw_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: BleQosApp()));
}

class BleQosApp extends StatelessWidget {
  const BleQosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE QoS Monitor',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const DeviceListScreen(),
        '/gw-home': (_) => const GwHomeScreen(),
        '/ed-home': (_) => const EdHomeScreen(),
      },
    );
  }
}
