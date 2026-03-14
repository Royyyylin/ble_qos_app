import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_models.dart';
import '../domain/connection_mode.dart';

/// Currently connected device state.
class ConnectedDevice {
  final String id;
  final String name;
  final ConnectionMode mode;

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.mode,
  });
}

/// Notifier for the currently connected device.
class ConnectedDeviceNotifier extends StateNotifier<ConnectedDevice?> {
  ConnectedDeviceNotifier() : super(null);

  void connect(ScannedDevice device) {
    state = ConnectedDevice(
      id: device.id,
      name: device.name,
      mode: device.mode,
    );
  }

  void disconnect() {
    state = null;
  }
}

final connectedDeviceProvider =
    StateNotifierProvider<ConnectedDeviceNotifier, ConnectedDevice?>((ref) {
  return ConnectedDeviceNotifier();
});
