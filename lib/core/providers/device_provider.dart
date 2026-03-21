import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_models.dart';
import '../ble/manufacturer_data.dart';
import '../domain/connection_mode.dart';

/// Currently connected device state.
class ConnectedDevice {
  final String id;
  final String name;
  final ConnectionMode mode;
  final int role; // ManufacturerData role constant
  final int? networkId;

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.mode,
    required this.role,
    this.networkId,
  });
}

/// Notifier for the currently connected device.
class ConnectedDeviceNotifier extends StateNotifier<ConnectedDevice?> {
  ConnectedDeviceNotifier() : super(null);

  void connect(ScannedDevice device) {
    final role = device.mfgData?.role ?? ManufacturerData.roleUnprovisioned;
    final mode = device.mfgData?.isGateway == true
        ? ConnectionMode.gwAggregate
        : ConnectionMode.edDirect;
    state = ConnectedDevice(
      id: device.id,
      name: device.name,
      mode: mode,
      role: role,
      networkId: device.networkId,
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
