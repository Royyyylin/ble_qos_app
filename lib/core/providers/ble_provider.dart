import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the list of connected BluetoothDevices.
/// flutter_blue_plus uses static methods on FlutterBluePlus,
/// so no singleton instance is needed.
///
/// This provider exposes helper access to connected devices.
final connectedDevicesProvider = FutureProvider<List<BluetoothDevice>>((ref) async {
  return FlutterBluePlus.connectedDevices;
});
