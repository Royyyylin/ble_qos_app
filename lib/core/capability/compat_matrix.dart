/// App/FW compatibility matrix — spec §6 (foundations/06-compat-matrix.md).
/// Code-embedded, no remote update. Feature availability determined by
/// capability bitmask + firmware version.

class CompatEntry {
  final String minFw;      // minimum firmware version (e.g. "1.2.0")
  final int capBit;        // CAP v1 bitmask bit
  final String capsV2Id;   // CAPS_V2 CBOR id (future)
  final String tabLabel;   // UI tab name (empty = no tab)

  const CompatEntry({
    required this.minFw,
    required this.capBit,
    required this.capsV2Id,
    this.tabLabel = '',
  });
}

const compatMatrix = <String, CompatEntry>{
  'qos_monitoring': CompatEntry(
    minFw: '1.2.0', capBit: 0x01, capsV2Id: 'qos_monitoring', tabLabel: 'Dashboard',
  ),
  'tp_test': CompatEntry(
    minFw: '1.2.0', capBit: 0x02, capsV2Id: 'tp_test', tabLabel: 'Demo',
  ),
  'alarm': CompatEntry(
    minFw: '1.2.0', capBit: 0x04, capsV2Id: 'alarm',
  ),
  'roster_management': CompatEntry(
    minFw: '1.2.0', capBit: 0x08, capsV2Id: 'roster_management', tabLabel: 'Roster',
  ),
  'ha_failover': CompatEntry(
    minFw: '1.2.0', capBit: 0x10, capsV2Id: 'ha_failover', tabLabel: 'HA',
  ),
  'control_profile': CompatEntry(
    minFw: '1.2.0', capBit: 0x20, capsV2Id: 'control_profile', tabLabel: 'Control',
  ),
};

/// Check if a firmware version meets the minimum requirement.
bool fwVersionMeetsMin(String fwVersion, String minRequired) {
  final fw = _parseVersion(fwVersion);
  final min = _parseVersion(minRequired);
  if (fw == null || min == null) return false;
  for (int i = 0; i < 3; i++) {
    if (fw[i] > min[i]) return true;
    if (fw[i] < min[i]) return false;
  }
  return true; // equal
}

List<int>? _parseVersion(String v) {
  // "1.2.0" or "1.2.0+5"
  final parts = v.split('+').first.split('.');
  if (parts.length < 3) return null;
  try {
    return parts.take(3).map(int.parse).toList();
  } catch (_) {
    return null;
  }
}
