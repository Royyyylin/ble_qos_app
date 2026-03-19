// lib/core/ble/manufacturer_data.dart
import 'dart:typed_data';

/// Parsed manufacturer specific data from BLE advertising — spec §4.5.
class ManufacturerData {
  final int protocolVersion;
  final int role;
  final int networkId;
  final int? edCount;   // GW only
  final int? haRole;    // GW only

  const ManufacturerData({
    required this.protocolVersion,
    required this.role,
    required this.networkId,
    this.edCount,
    this.haRole,
  });

  bool get isGateway => role == 2;
  bool get isEndDevice => role == 1;
  bool get isCC => role == 4;
  bool get isUnprovisioned => role == 0;

  /// Parse manufacturer data payload. Returns null if too short.
  /// Format: [protocol:1][role:1][network_id:2LE][ed_count:1?][ha_role:1?]
  static ManufacturerData? parse(Uint8List bytes) {
    if (bytes.length < 4) return null;

    final bd = ByteData.sublistView(bytes);
    final protocol = bd.getUint8(0);
    final role = bd.getUint8(1);
    final networkId = bd.getUint16(2, Endian.little);

    int? edCount;
    int? haRole;
    if (bytes.length >= 5) edCount = bd.getUint8(4);
    if (bytes.length >= 6) haRole = bd.getUint8(5);

    return ManufacturerData(
      protocolVersion: protocol,
      role: role,
      networkId: networkId,
      edCount: edCount,
      haRole: haRole,
    );
  }
}
