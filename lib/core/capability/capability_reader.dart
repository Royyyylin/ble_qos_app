import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../ble/ble_gatt.dart';
import '../ble/manufacturer_data.dart';
import '../gatt/gatt_uuids.dart';
import 'capability_model.dart';
import 'capability_registry.dart';

/// Reads device capabilities following the negotiation read order:
/// 1. Read CAPABILITY GATT characteristic (6f8a9c19)
/// 2. If absent or read fails → fallback to role-based defaults
/// 3. Negotiate parsed caps against registry
class CapabilityReader {
  CapabilityReader._();

  /// Read capabilities from GATT, falling back to role-based defaults.
  /// Returns the list of [Capability] to negotiate against the registry.
  static Future<List<Capability>> readCapabilities({
    required BleGatt gatt,
    required int deviceRole,
  }) async {
    try {
      final bytes = await gatt.read(GattUuids.capability);
      final caps = parseCapabilityBytes(bytes);
      if (caps.isNotEmpty) {
        debugPrint('[CAP_READ] read ${caps.length} capabilities from GATT');
        return caps;
      }
    } catch (e) {
      debugPrint('[CAP_READ] GATT read failed: $e — using role fallback');
    }
    // Fallback: role-based default capabilities
    return CapabilityRegistry.fallbackForRole(deviceRole);
  }

  /// Parse binary CAPABILITY characteristic value.
  /// Format: [count:1][id_len:1][id:N (UTF-8)][version:1]...
  static List<Capability> parseCapabilityBytes(Uint8List bytes) {
    if (bytes.isEmpty) return [];

    final caps = <Capability>[];
    final count = bytes[0];
    int offset = 1;

    for (int i = 0; i < count && offset < bytes.length; i++) {
      if (offset >= bytes.length) break;
      final idLen = bytes[offset++];
      if (offset + idLen + 1 > bytes.length) break;
      final idBytes = bytes.sublist(offset, offset + idLen);
      offset += idLen;
      final version = bytes[offset++];
      final id = utf8.decode(idBytes);
      caps.add(Capability(id: id, version: version));
    }

    return caps;
  }
}
