import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gatt/gatt_uuids.dart';
import '../providers/ble_provider.dart';
import 'ble_models.dart';

/// BLE scanner — filters by QoS Service UUID (0x1820).
class BleScanner {
  BleScanner(this._ble);

  final FlutterReactiveBle _ble;
  StreamSubscription<DiscoveredDevice>? _sub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();

  Stream<List<ScannedDevice>> get devices => _controller.stream;
  List<ScannedDevice> get currentDevices => _devices.values.toList();

  void start() {
    _devices.clear();
    _sub?.cancel();
    _sub = _ble
        .scanForDevices(
          withServices: [Uuid.parse(GattUuids.serviceQos)],
        )
        .listen((device) {
      _devices[device.id] = ScannedDevice(
        id: device.id,
        name: device.name,
        rssi: device.rssi,
        mode: ScannedDevice.modeFromName(device.name),
      );
      _controller.add(_devices.values.toList());
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

/// Riverpod provider for the scanner.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final ble = ref.watch(bleInstanceProvider);
  final scanner = BleScanner(ble);
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
