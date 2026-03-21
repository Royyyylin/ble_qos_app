// lib/core/ble/manufacturer_data.dart
import 'dart:typed_data';

/// Parsed manufacturer specific data from BLE advertising — spec §4.5.
class ManufacturerData {
  /// Role constants matching firmware adv_mfg.h definitions.
  /// ADV_MFG_ROLE_GW=0x01, ADV_MFG_ROLE_ED=0x02.
  static const int roleUnprovisioned = 0x00;
  static const int roleGateway = 0x01;
  static const int roleEndDevice = 0x02;
  static const int roleCentralController = 0x04;

  /// Display name → uint8 role value mapping. SSOT for provisioning & admin UI.
  static const Map<String, int> _roleMap = {
    'Gateway': roleGateway,
    'End Device': roleEndDevice,
    'Central Controller': roleCentralController,
  };

  /// All valid role display names for dropdown selectors.
  static List<String> get roleNames => _roleMap.keys.toList();

  /// Convert display name to uint8 role value. Throws if unknown.
  static int roleFromString(String name) {
    final value = _roleMap[name];
    if (value == null) {
      throw ArgumentError('Unknown role name: $name');
    }
    return value;
  }

  /// Convert uint8 role value to display name.
  static String roleName(int role) => switch (role) {
    roleGateway => 'Gateway',
    roleEndDevice => 'End Device',
    roleCentralController => 'Central Controller',
    roleUnprovisioned => 'Unprovisioned',
    _ => 'Unknown (0x${role.toRadixString(16)})',
  };

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

  bool get isGateway => role == roleGateway;
  bool get isEndDevice => role == roleEndDevice;
  bool get isCC => role == roleCentralController;
  bool get isUnprovisioned => role == roleUnprovisioned;

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
