import '../domain/connection_mode.dart';

/// Discovered BLE device info from scan results.
class ScannedDevice {
  final String id;
  final String name;
  final int rssi;
  final ConnectionMode mode;

  const ScannedDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.mode,
  });

  /// Determine device type from advertising name prefix.
  /// GW devices: name starts with "GW-"
  /// ED devices: name starts with "ED-" or "QoS-"
  static ConnectionMode modeFromName(String name) {
    if (name.startsWith('GW-')) return ConnectionMode.gwAggregate;
    return ConnectionMode.edDirect;
  }
}

/// BLE connection state.
enum BleConnectionState {
  disconnected,
  connecting,
  handshaking, // PEER_ROLE write in progress
  connected,
}
