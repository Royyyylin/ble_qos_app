import 'manufacturer_data.dart';

/// Device connectivity status — spec §4.1.
enum DeviceStatus {
  online,   // advertising seen < 10s ago
  stale,    // 10s–30s since last adv
  offline,  // > 30s since last adv
}

/// Determine device status from lastSeen time — spec §4.1.
/// [staleDuration] = 10s, [offlineDuration] = 30s.
DeviceStatus deviceStatusFromLastSeen(
  DateTime lastSeen, {
  DateTime? now,
  Duration staleDuration = const Duration(seconds: 10),
  Duration offlineDuration = const Duration(seconds: 30),
}) {
  final current = now ?? DateTime.now();
  final elapsed = current.difference(lastSeen);
  if (elapsed >= offlineDuration) return DeviceStatus.offline;
  if (elapsed >= staleDuration) return DeviceStatus.stale;
  return DeviceStatus.online;
}

/// EMA (Exponential Moving Average) for RSSI smoothing — spec §4.1.
/// smoothed = alpha * newValue + (1 - alpha) * previous
double emaRssi(int newRssi, double? previous, {double alpha = 0.3}) {
  if (previous == null) return newRssi.toDouble();
  return alpha * newRssi + (1 - alpha) * previous;
}

/// Discovered BLE device info from scan results.
class ScannedDevice {
  final String id;
  final String name;
  final int rssi;
  final double smoothedRssi;
  final DeviceStatus status;
  final DateTime lastSeen;
  final ManufacturerData? mfgData;
  final String? alias;

  const ScannedDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.smoothedRssi,
    required this.status,
    required this.lastSeen,
    this.mfgData,
    this.alias,
  });

  /// Display name: alias if set, otherwise advertising name.
  String get displayName => alias ?? name;

  /// Role string derived from manufacturer data or name prefix.
  String get roleLabel {
    if (mfgData != null) {
      if (mfgData!.isGateway) return 'Gateway';
      if (mfgData!.isEndDevice) return 'End Device';
      if (mfgData!.isCC) return 'Central Controller';
      if (mfgData!.isUnprovisioned) return 'Unprovisioned';
    }
    if (name.startsWith('GW-')) return 'Gateway';
    return 'End Device';
  }

  /// Network ID from manufacturer data.
  int? get networkId => mfgData?.networkId;

  /// Copy with updated fields.
  ScannedDevice copyWith({
    int? rssi,
    double? smoothedRssi,
    DeviceStatus? status,
    DateTime? lastSeen,
    ManufacturerData? mfgData,
    String? alias,
  }) {
    return ScannedDevice(
      id: id,
      name: name,
      rssi: rssi ?? this.rssi,
      smoothedRssi: smoothedRssi ?? this.smoothedRssi,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      mfgData: mfgData ?? this.mfgData,
      alias: alias ?? this.alias,
    );
  }
}

/// BLE connection state.
enum BleConnectionState {
  disconnected,
  connecting,
  handshaking, // PEER_ROLE write in progress
  connected,
}
