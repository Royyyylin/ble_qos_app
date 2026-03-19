import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gatt/gatt_uuids.dart';
import 'ble_models.dart';

/// BLE scanner — filters by QoS Service UUID (0x1820).
class BleScanner {
  StreamSubscription<List<ScanResult>>? _sub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();

  Stream<List<ScannedDevice>> get devices => _controller.stream;
  List<ScannedDevice> get currentDevices => _devices.values.toList();

  void start() {
    _devices.clear();
    _sub?.cancel();

    _sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        _devices[r.device.remoteId.str] = ScannedDevice(
          id: r.device.remoteId.str,
          name: r.advertisementData.advName,
          rssi: r.rssi,
          mode: ScannedDevice.modeFromName(r.advertisementData.advName),
        );
      }
      _controller.add(_devices.values.toList());
    });

    FlutterBluePlus.startScan(
      withServices: [Guid(GattUuids.serviceQos)],
      androidUsesFineLocation: false,
    );
  }

  Future<void> stop() async {
    _sub?.cancel();
    _sub = null;
    await FlutterBluePlus.stopScan();
  }

  Future<void> dispose() async {
    await stop();
    _controller.close();
  }
}

/// Riverpod provider for the scanner.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
