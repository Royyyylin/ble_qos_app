import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/ble/ble_connector.dart';
import '../../core/ble/ble_models.dart';
import '../../core/ble/ble_scanner.dart';
import '../../core/providers/device_provider.dart';
import 'device_tile.dart';

/// Scan screen — discovers GW and ED devices advertising QoS Service.
class DeviceListScreen extends ConsumerStatefulWidget {
  const DeviceListScreen({super.key});

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  List<ScannedDevice> _devices = [];
  bool _scanning = false;
  BleScanner? _scanner;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    // Request BLE permissions
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    _scanner = ref.read(bleScannerProvider);
    _scanner!.start();
    setState(() => _scanning = true);

    _scanner!.devices.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });
  }

  void _stopScan() {
    _scanner?.stop();
    if (mounted) setState(() => _scanning = false);
  }

  void _onDeviceTap(ScannedDevice device) {
    _stopScan();
    ref.read(connectedDeviceProvider.notifier).connect(device);
    ref.read(bleConnectorProvider).connect(device.id);

    // Derive mode from name prefix (v1 compat, v2 uses roleLabel)
    final route = device.name.startsWith('GW-')
        ? '/gw-home'
        : '/ed-home';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE QoS Monitor'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            onPressed: _scanning ? _stopScan : _startScan,
          ),
        ],
      ),
      body: _devices.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scanning) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_scanning ? 'Scanning...' : 'No devices found'),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _devices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = _devices[index];
                return DeviceTile(
                  device: device,
                  onTap: () => _onDeviceTap(device),
                );
              },
            ),
    );
  }
}
