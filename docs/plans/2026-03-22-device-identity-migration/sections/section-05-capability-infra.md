# Section 5: Capability GATT Read Infrastructure

**Layer:** Infrastructure
**Files Owned:**
- `lib/core/capability/capability_reader.dart` (create)
- `test/core/capability/capability_reader_test.dart` (create)

**Depends On:** Section 2 (DegradationInfo), Section 4 (BleConnector with identity)
**Tasks:** 2 (Task 12, Task 13)

---

### Task 12: [Infrastructure] CapabilityReader — GATT Read with Role Fallback

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Create: `lib/core/capability/capability_reader.dart`
- Create: `test/core/capability/capability_reader_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/capability/capability_reader_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_reader.dart';

void main() {
  group('CapabilityReader', () {
    group('parseCapabilityBytes', () {
      test('given_valid_bytes_when_parsed_then_returns_capability_list', () {
        // Format: [count:1][id_len:1][id:N][version:1]...
        // 1 capability: "qos_monitor" v1
        final idBytes = 'qos_monitor'.codeUnits;
        final bytes = Uint8List.fromList([
          1, // count
          idBytes.length, // id_len
          ...idBytes, // id
          1, // version
        ]);
        final caps = CapabilityReader.parseCapabilityBytes(bytes);
        expect(caps, hasLength(1));
        expect(caps.first.id, 'qos_monitor');
        expect(caps.first.version, 1);
      });

      test('given_multiple_caps_when_parsed_then_returns_all', () {
        final id1 = 'qos_monitor'.codeUnits;
        final id2 = 'ha_runtime'.codeUnits;
        final bytes = Uint8List.fromList([
          2, // count
          id1.length, ...id1, 1, // qos_monitor v1
          id2.length, ...id2, 2, // ha_runtime v2
        ]);
        final caps = CapabilityReader.parseCapabilityBytes(bytes);
        expect(caps, hasLength(2));
        expect(caps[0].id, 'qos_monitor');
        expect(caps[0].version, 1);
        expect(caps[1].id, 'ha_runtime');
        expect(caps[1].version, 2);
      });

      test('given_empty_bytes_when_parsed_then_returns_empty_list', () {
        final caps = CapabilityReader.parseCapabilityBytes(Uint8List(0));
        expect(caps, isEmpty);
      });

      test('given_truncated_bytes_when_parsed_then_returns_partial', () {
        // Only count byte, no capability data
        final caps = CapabilityReader.parseCapabilityBytes(Uint8List.fromList([2]));
        expect(caps, isEmpty);
      });
    });
  });
}
>>>
NOTE: Tests for GATT CAPABILITY characteristic binary parsing.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/capability/capability_reader_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/capability/capability_reader.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
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
>>>
NOTE: GATT capability reader with role-based fallback and binary parser.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/capability/capability_reader_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/capability/capability_reader.dart test/core/capability/capability_reader_test.dart && git commit -m "infra(capability): add CapabilityReader with GATT read and role-based fallback"`

---

### Task 13: [Infrastructure] CapabilityReader Riverpod Provider

**Layer:** Infrastructure
**DDD Pattern:** Adapter (provider)
**Files:**
- Modify: `lib/core/capability/capability_reader.dart`

**Step 1: No test needed (provider wiring)**

**Step 2: Skip**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/capability/capability_reader.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'package:flutter/foundation.dart';
>>>
NEW_CONTENT: <<<
import 'package:flutter_riverpod/flutter_riverpod.dart';
>>>
NOTE: Add Riverpod import for provider.
```

```
EDIT_BLOCK 2
FILE: lib/core/capability/capability_reader.dart
ACTION: APPEND
NEW_CONTENT: <<<

/// Provider that reads and negotiates capabilities for the connected device.
/// Returns a NegotiationResult based on GATT read → role fallback negotiation order.
final capabilityNegotiationProvider = FutureProvider<NegotiationResult>((ref) async {
  // Import needed for this provider
  final connDevice = ref.watch(connectedDeviceProvider);
  if (connDevice == null) {
    return const NegotiationResult(
      enabledTabs: [], incompatible: [], unknown: [],
    );
  }

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final role = connDevice.role;

  final caps = await CapabilityReader.readCapabilities(
    gatt: gatt,
    deviceRole: role,
  );
  return CapabilityNegotiator.negotiate(caps);
});
>>>
NOTE: FutureProvider for capability negotiation with GATT read order.
```

```
EDIT_BLOCK 3
FILE: lib/core/capability/capability_reader.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import '../gatt/gatt_uuids.dart';
>>>
NEW_CONTENT: <<<
import '../ble/ble_connector.dart';
import '../providers/device_provider.dart';
import 'capability_negotiator.dart';
>>>
NOTE: Imports for the provider — BleConnector, connectedDeviceProvider, CapabilityNegotiator.
```

**Step 4: Run to verify it compiles**
Run: `flutter test test/core/capability/capability_reader_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/capability/capability_reader.dart && git commit -m "infra(capability): add capabilityNegotiationProvider with GATT read order"`
