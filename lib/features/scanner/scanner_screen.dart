import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/ble/ble_models.dart';
import '../../core/ble/ble_scanner.dart';
import '../../core/providers/device_provider.dart';
import '../../core/theme/app_colors.dart';
import 'fleet_summary.dart';
import 'scan_device_tile.dart';

/// Fleet Overview Dashboard — spec §4.
/// Shows fleet summary cards, search bar, and device list grouped by network_id.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  List<ScannedDevice> _devices = [];
  String _searchQuery = '';
  bool _scanning = false;
  BleScanner? _scanner;

  @override
  void initState() {
    super.initState();
    // Auto-start scan on screen load
    Future.microtask(() => _startScan());
  }

  Future<void> _startScan() async {
    try {
      // Request BLE permissions on Android
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();
        if (statuses[Permission.bluetoothScan] != PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bluetooth scan permission denied')),
            );
          }
          return;
        }
      }

      // Ensure Bluetooth adapter is on
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      _scanner = ref.read(bleScannerProvider);
      _scanner!.start();
      if (mounted) setState(() => _scanning = true);

      _scanner!.devices.listen((devices) {
        if (mounted) setState(() => _devices = devices);
      });
    } catch (_) {
      // BLE not available (e.g., in tests or simulator)
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _stopScan({bool updateState = true}) {
    _scanner?.stop();
    if (updateState && mounted) setState(() => _scanning = false);
  }

  void _onDeviceTap(ScannedDevice device) {
    // Set connected device state so providers (statusStreamProvider, etc.) can subscribe
    ref.read(connectedDeviceProvider.notifier).connect(device);
    // Navigate to device detail via GoRouter
    context.go('/device/${device.id}');
  }

  List<ScannedDevice> get _filteredDevices {
    if (_searchQuery.isEmpty) return _devices;
    final q = _searchQuery.toLowerCase();
    return _devices.where((d) =>
      d.displayName.toLowerCase().contains(q) ||
      d.id.toLowerCase().contains(q) ||
      d.roleLabel.toLowerCase().contains(q)
    ).toList();
  }

  /// Group devices by networkId for display.
  Map<int?, List<ScannedDevice>> get _groupedDevices {
    final grouped = <int?, List<ScannedDevice>>{};
    for (final d in _filteredDevices) {
      (grouped[d.networkId] ??= []).add(d);
    }
    return grouped;
  }

  @override
  void dispose() {
    _stopScan(updateState: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Overview'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            onPressed: _scanning ? _stopScan : _startScan,
            tooltip: _scanning ? 'Stop scan' : 'Start scan',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // context.go('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Fleet summary stat cards
          FleetSummary(devices: _devices),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search devices...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceVar,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Device list
          Expanded(
            child: _filteredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_scanning) const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _scanning ? 'Scanning...' : 'No devices found',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _buildGroupedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final groups = _groupedDevices;
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) => (a ?? 9999).compareTo(b ?? 9999));

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final netId = sortedKeys[index];
        final devices = groups[netId]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                netId != null ? 'Network $netId' : 'Unknown Network',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...devices.map((d) => ScanDeviceTile(
              device: d,
              onTap: () => _onDeviceTap(d),
            )),
          ],
        );
      },
    );
  }
}
