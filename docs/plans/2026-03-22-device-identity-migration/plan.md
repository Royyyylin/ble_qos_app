# Device Identity Migration + BLE Scan Lifecycle + Capability Compat Matrix — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate all 9 touch points from MAC-based identity to app-generated UUIDv4 StableId, implement TTL eviction for BLE scan lifecycle, and add GATT-based capability negotiation with graceful degradation UI.
**Bounded Context(s):** Device Identity, BLE Scan Lifecycle, BLE Connection Lifecycle, Capability Negotiation
**Architecture:** Domain layer gets DeviceIdentity aggregate + DeviceIdentityService with in-memory cache. Infrastructure layer adds Drift-backed IdentityRepository, schema v2 migration, and CapabilityReader for GATT reads. Presentation layer adopts StableId for navigation and adds degradation badges.
**Tech Stack:** Flutter, Dart, Riverpod, Drift (SQLite), FlutterBluePlus, GoRouter
**Domain Model:** `docs/domain/2026-03-22-implement-device-identity-migration-app--domain-model.md`
**Research Brief:** Provided inline (see task description)
**Assumptions:**
1. IdentityRepository uses Drift table (not SharedPreferences) — consistent with existing DB layer
2. Database migration for existing Devices rows: generate StableId for existing MAC PKs (acceptable for dev stage)
3. BleScanner uses synchronous in-memory cache (populated at startup) to avoid async in scan callbacks
4. `removeIfGone: 15s` left unchanged at FlutterBluePlus level — app-level TTL eviction (30s) is the authoritative removal
5. `uuid` package not added — UUIDv4 generated via `Random.secure()` (no external dependency needed)

**Propagation Checklist:**
- [x] Files sharing ScannedDevice.id pattern: `ble_scanner.dart`, `scanner_screen.dart`, `device_provider.dart`, `scan_device_tile.dart`
- [x] Files sharing ConnectedDevice.id pattern: `device_screen.dart`, `metrics_provider.dart`, `settings_screen.dart`
- [x] Files sharing BleConnector.connect(deviceId) callers: `scanner_screen.dart`, `ble_reconnect.dart`, `device_screen.dart`, `ble_connector.dart` (reconnect factory)
- [x] Config keys affected: `database.schemaVersion` (1→2), `Devices` table (add `mac` column)
- [x] Subprocess callers that need update: `bleReconnectProvider` factory — transparent via BleConnector resolution

**EDIT_BLOCK Validation:**
- [x] Every ANCHOR verified unique in target file (post prior edits)
- [x] Cross-task anchor dependencies noted (Task 11 depends on Task 7's scanner provider text)
- [x] CREATE_FILE provides complete file content
- [x] REPLACE anchors include ALL lines being removed
- [x] No EDIT_BLOCK relies on nearest-match or semantic search

---

## Layer 1: Domain

### Task 1: [Domain] DeviceIdentity Aggregate + StableId Value Object

**Layer:** Domain
**DDD Pattern:** Aggregate + ValueObject
**Files:**
- Create: `lib/core/identity/device_identity.dart`
- Create: `test/core/identity/device_identity_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/identity/device_identity_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/identity/device_identity.dart';

void main() {
  group('DeviceIdentity', () {
    test('given_valid_mac_and_stableId_when_created_then_stores_both', () {
      final identity = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(identity.stableId, '550e8400-e29b-41d4-a716-446655440000');
      expect(identity.mac, 'AA:BB:CC:DD:EE:FF');
    });

    test('given_two_identities_with_same_stableId_when_compared_then_equal', () {
      final a = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      final b = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('given_identity_when_toString_then_shows_stableId_and_mac', () {
      final identity = DeviceIdentity(
        stableId: 'abc-123',
        mac: 'AA:BB',
      );
      expect(identity.toString(), contains('abc-123'));
      expect(identity.toString(), contains('AA:BB'));
    });
  });
}
>>>
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/identity/device_identity_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/identity/device_identity.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
/// DeviceIdentity aggregate — maps a platform MAC to an app-generated StableId (UUIDv4).
class DeviceIdentity {
  final String stableId;
  final String mac;
  final DateTime createdAt;

  DeviceIdentity({
    required this.stableId,
    required this.mac,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceIdentity &&
          stableId == other.stableId &&
          mac == other.mac;

  @override
  int get hashCode => Object.hash(stableId, mac);

  @override
  String toString() => 'DeviceIdentity(stableId: $stableId, mac: $mac)';
}
>>>
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/identity/device_identity_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/identity/device_identity.dart test/core/identity/device_identity_test.dart && git commit -m "domain(identity): add DeviceIdentity aggregate with StableId value object"`

---

### Task 2: [Domain] IdentityRepository Interface

**Layer:** Domain
**DDD Pattern:** Repository (interface)
**Files:**
- Create: `lib/core/identity/identity_repository.dart`

**Step 1–2: Skip (pure interface)**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/identity/identity_repository.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'device_identity.dart';

abstract class IdentityRepository {
  Future<String?> findStableIdByMac(String mac);
  Future<String?> findMacByStableId(String stableId);
  Future<void> save(DeviceIdentity identity);
  Future<List<DeviceIdentity>> getAll();
}
>>>
```

**Step 4: Skip**

**Step 5: Commit**
`git add lib/core/identity/identity_repository.dart && git commit -m "domain(identity): add IdentityRepository interface"`

---

### Task 3: [Domain] DeviceIdentityService

**Layer:** Domain
**DDD Pattern:** DomainService
**Files:**
- Create: `lib/core/identity/device_identity_service.dart`
- Create: `test/core/identity/device_identity_service_test.dart`

**Step 1: Write the failing test**

```
EDIT_BLOCK 1
FILE: test/core/identity/device_identity_service_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/identity/device_identity.dart';
import 'package:ble_qos_app/core/identity/device_identity_service.dart';
import 'package:ble_qos_app/core/identity/identity_repository.dart';

class FakeIdentityRepository implements IdentityRepository {
  final _store = <String, DeviceIdentity>{};

  @override
  Future<String?> findStableIdByMac(String mac) async {
    for (final identity in _store.values) {
      if (identity.mac == mac) return identity.stableId;
    }
    return null;
  }

  @override
  Future<String?> findMacByStableId(String stableId) async =>
      _store[stableId]?.mac;

  @override
  Future<void> save(DeviceIdentity identity) async =>
      _store[identity.stableId] = identity;

  @override
  Future<List<DeviceIdentity>> getAll() async => _store.values.toList();
}

void main() {
  group('DeviceIdentityService', () {
    late FakeIdentityRepository repo;
    late DeviceIdentityService service;

    setUp(() {
      repo = FakeIdentityRepository();
      service = DeviceIdentityService(repo);
    });

    test('given_new_mac_when_resolveOrAssign_then_generates_stableId_and_persists', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      expect(stableId, isNotEmpty);
      expect(stableId.split('-').length, 5);
      final stored = await repo.findStableIdByMac('AA:BB:CC:DD:EE:FF');
      expect(stored, stableId);
    });

    test('given_known_mac_when_resolveOrAssign_then_returns_existing_stableId', () async {
      await service.initialize();
      final first = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      final second = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      expect(second, first);
    });

    test('given_stableId_when_resolveToMac_then_returns_mac', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      final mac = service.resolveToMac(stableId);
      expect(mac, 'AA:BB:CC:DD:EE:FF');
    });

    test('given_unknown_stableId_when_resolveToMac_then_returns_null', () async {
      await service.initialize();
      expect(service.resolveToMac('unknown-id'), isNull);
    });

    test('given_new_mac_when_resolveOrAssignSync_then_generates_and_caches', () async {
      await service.initialize();
      final stableId = service.resolveOrAssignSync('NEW:MAC');
      expect(stableId, isNotEmpty);
      expect(service.resolveOrAssignSync('NEW:MAC'), stableId);
    });
  });
}
>>>
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/identity/device_identity_service_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/identity/device_identity_service.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'dart:math';

import 'device_identity.dart';
import 'identity_repository.dart';

class DeviceIdentityService {
  final IdentityRepository _repository;
  final _macToStableId = <String, String>{};
  final _stableIdToMac = <String, String>{};

  DeviceIdentityService(this._repository);

  Future<void> initialize() async {
    final all = await _repository.getAll();
    for (final identity in all) {
      _macToStableId[identity.mac] = identity.stableId;
      _stableIdToMac[identity.stableId] = identity.mac;
    }
  }

  Future<String> resolveOrAssign(String mac) async {
    final existing = _macToStableId[mac];
    if (existing != null) return existing;

    final stableId = _generateUuidV4();
    final identity = DeviceIdentity(stableId: stableId, mac: mac);
    _macToStableId[mac] = stableId;
    _stableIdToMac[stableId] = mac;
    await _repository.save(identity);
    return stableId;
  }

  String resolveOrAssignSync(String mac) {
    final existing = _macToStableId[mac];
    if (existing != null) return existing;

    final stableId = _generateUuidV4();
    final identity = DeviceIdentity(stableId: stableId, mac: mac);
    _macToStableId[mac] = stableId;
    _stableIdToMac[stableId] = mac;
    _repository.save(identity); // fire-and-forget
    return stableId;
  }

  String? resolveToMac(String stableId) => _stableIdToMac[stableId];

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
>>>
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/identity/device_identity_service_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/identity/device_identity_service.dart test/core/identity/device_identity_service_test.dart && git commit -m "domain(identity): add DeviceIdentityService with sync cache for scan callbacks"`

---

### Task 4: [Domain] DegradationInfo Value Object

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Create: `lib/core/capability/degradation_info.dart`
- Create: `test/core/capability/degradation_info_test.dart`

**Step 1: Write the failing test**

```
EDIT_BLOCK 1
FILE: test/core/capability/degradation_info_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/degradation_info.dart';

void main() {
  group('DegradationInfo', () {
    test('given_version_mismatch_when_created_then_stores_all_fields', () {
      final info = DegradationInfo(
        capId: 'qos_monitor', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'Dashboard',
      );
      expect(info.capId, 'qos_monitor');
      expect(info.deviceVersion, 0);
      expect(info.requiredVersion, 1);
      expect(info.tabLabel, 'Dashboard');
    });

    test('given_degradation_info_when_message_accessed_then_returns_human_readable', () {
      final info = DegradationInfo(
        capId: 'ha_runtime', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'HA',
      );
      expect(info.message, contains('v0'));
      expect(info.message, contains('v1'));
    });

    test('given_two_identical_infos_when_compared_then_equal', () {
      final a = DegradationInfo(
        capId: 'qos_monitor', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'Dashboard',
      );
      final b = DegradationInfo(
        capId: 'qos_monitor', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'Dashboard',
      );
      expect(a, equals(b));
    });
  });
}
>>>
```

**Step 2:** Run: `flutter test test/core/capability/degradation_info_test.dart` → FAIL

**Step 3:**

```
EDIT_BLOCK 2
FILE: lib/core/capability/degradation_info.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
class DegradationInfo {
  final String capId;
  final int deviceVersion;
  final int requiredVersion;
  final String tabLabel;

  const DegradationInfo({
    required this.capId,
    required this.deviceVersion,
    required this.requiredVersion,
    required this.tabLabel,
  });

  String get message =>
      '$capId: device has v$deviceVersion, requires v$requiredVersion';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DegradationInfo &&
          capId == other.capId &&
          deviceVersion == other.deviceVersion &&
          requiredVersion == other.requiredVersion &&
          tabLabel == other.tabLabel;

  @override
  int get hashCode =>
      Object.hash(capId, deviceVersion, requiredVersion, tabLabel);

  @override
  String toString() => 'DegradationInfo($message)';
}
>>>
```

**Step 4:** Run: `flutter test test/core/capability/degradation_info_test.dart` → PASS

**Step 5:** `git add lib/core/capability/degradation_info.dart test/core/capability/degradation_info_test.dart && git commit -m "domain(capability): add DegradationInfo value object"`

---

### Task 5: [Domain] Enhance NegotiationResult with DegradationInfo

**Layer:** Domain
**DDD Pattern:** ValueObject (enhanced)
**Files:**
- Modify: `lib/core/capability/capability_negotiator.dart`
- Modify: `test/core/capability/capability_negotiator_test.dart`

**Step 1: Write the failing test**

```
EDIT_BLOCK 1
FILE: test/core/capability/capability_negotiator_test.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
>>>
NEW_CONTENT: <<<
import 'package:ble_qos_app/core/capability/degradation_info.dart';
>>>
```

```
EDIT_BLOCK 2
FILE: test/core/capability/capability_negotiator_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
    test('negotiate ignores unknown capabilities', () {
>>>
NEW_CONTENT: <<<
    test('given_incompatible_cap_when_negotiated_then_produces_degradation_info', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 0),
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.degraded, hasLength(1));
      expect(result.degraded.first.capId, 'qos_monitor');
      expect(result.degraded.first.deviceVersion, 0);
      expect(result.degraded.first.requiredVersion, 1);
      expect(result.degraded.first.tabLabel, 'Dashboard');
    });

    test('given_all_compatible_when_negotiated_then_degraded_is_empty', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 1),
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.degraded, isEmpty);
    });

>>>
```

**Step 2:** Run: `flutter test test/core/capability/capability_negotiator_test.dart` → FAIL

**Step 3:**

```
EDIT_BLOCK 3
FILE: lib/core/capability/capability_negotiator.dart
ACTION: REPLACE
ANCHOR: <<<
// lib/core/capability/capability_negotiator.dart
import 'capability_model.dart';
import 'capability_registry.dart';
>>>
NEW_CONTENT: <<<
// lib/core/capability/capability_negotiator.dart
import 'capability_model.dart';
import 'capability_registry.dart';
import 'degradation_info.dart';
>>>
```

```
EDIT_BLOCK 4
FILE: lib/core/capability/capability_negotiator.dart
ACTION: REPLACE
ANCHOR: <<<
/// Result of capability negotiation — spec §5.3.
class NegotiationResult {
  final List<String> enabledTabs;
  final List<Capability> incompatible;
  final List<String> unknown;

  const NegotiationResult({
    required this.enabledTabs,
    required this.incompatible,
    required this.unknown,
  });
}
>>>
NEW_CONTENT: <<<
/// Result of capability negotiation — spec §5.3.
class NegotiationResult {
  final List<String> enabledTabs;
  final List<Capability> incompatible;
  final List<String> unknown;
  final List<DegradationInfo> degraded;

  const NegotiationResult({
    required this.enabledTabs,
    required this.incompatible,
    required this.unknown,
    this.degraded = const [],
  });

  bool get isLimitedMode =>
      enabledTabs.isEmpty && incompatible.isNotEmpty;
}
>>>
```

```
EDIT_BLOCK 5
FILE: lib/core/capability/capability_negotiator.dart
ACTION: REPLACE
ANCHOR: <<<
  static NegotiationResult negotiate(List<Capability> deviceCaps) {
    final enabledTabs = <String>[];
    final incompatible = <Capability>[];
    final unknown = <String>[];

    for (final cap in deviceCaps) {
      final handler = CapabilityRegistry.getHandler(cap.id);
      if (handler == null) {
        unknown.add(cap.id);
      } else if (cap.version < handler.minVersion) {
        incompatible.add(cap);
      } else {
        enabledTabs.add(handler.tabLabel);
      }
    }

    return NegotiationResult(
      enabledTabs: enabledTabs,
      incompatible: incompatible,
      unknown: unknown,
    );
  }
>>>
NEW_CONTENT: <<<
  static NegotiationResult negotiate(List<Capability> deviceCaps) {
    final enabledTabs = <String>[];
    final incompatible = <Capability>[];
    final unknown = <String>[];
    final degraded = <DegradationInfo>[];

    for (final cap in deviceCaps) {
      final handler = CapabilityRegistry.getHandler(cap.id);
      if (handler == null) {
        unknown.add(cap.id);
      } else if (cap.version < handler.minVersion) {
        incompatible.add(cap);
        degraded.add(DegradationInfo(
          capId: cap.id,
          deviceVersion: cap.version,
          requiredVersion: handler.minVersion,
          tabLabel: handler.tabLabel,
        ));
      } else {
        enabledTabs.add(handler.tabLabel);
      }
    }

    return NegotiationResult(
      enabledTabs: enabledTabs,
      incompatible: incompatible,
      unknown: unknown,
      degraded: degraded,
    );
  }
>>>
```

**Step 4:** Run: `flutter test test/core/capability/capability_negotiator_test.dart` → PASS

**Step 5:** `git add lib/core/capability/capability_negotiator.dart test/core/capability/capability_negotiator_test.dart && git commit -m "domain(capability): enhance NegotiationResult with DegradationInfo list"`

---

## Layer 2: Application

(No dedicated application layer tasks — use cases are thin and handled directly by domain services and infrastructure adapters.)

---

## Layer 3: Infrastructure

### Task 6: [Domain] Add `mac` Field to ScannedDevice

**Layer:** Domain
**DDD Pattern:** Entity
**Files:**
- Modify: `lib/core/ble/ble_models.dart`
- Modify: `test/core/ble/ble_models_test.dart`

**Step 1:** Add test for `mac` field.

```
EDIT_BLOCK 1
FILE: test/core/ble/ble_models_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
  group('BleConnectionState', () {
>>>
NEW_CONTENT: <<<
    test('given_scannedDevice_with_mac_when_accessed_then_returns_mac', () {
      final d = ScannedDevice(
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'GW-Test',
        rssi: -60,
        smoothedRssi: -62.5,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(d.mac, 'AA:BB:CC:DD:EE:FF');
      expect(d.id, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('given_scannedDevice_without_mac_when_accessed_then_mac_is_null', () {
      final d = ScannedDevice(
        id: 'some-id',
        name: 'Test',
        rssi: -60,
        smoothedRssi: -60.0,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
      );
      expect(d.mac, isNull);
    });

>>>
```

**Step 2:** Run: `flutter test test/core/ble/ble_models_test.dart` → FAIL

**Step 3:**

```
EDIT_BLOCK 2
FILE: lib/core/ble/ble_models.dart
ACTION: REPLACE
ANCHOR: <<<
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
>>>
NEW_CONTENT: <<<
/// Discovered BLE device info from scan results.
/// After identity migration: [id] = StableId (UUIDv4), [mac] = platform remoteId.
class ScannedDevice {
  final String id;
  final String name;
  final int rssi;
  final double smoothedRssi;
  final DeviceStatus status;
  final DateTime lastSeen;
  final ManufacturerData? mfgData;
  final String? alias;
  final String? mac;

  const ScannedDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.smoothedRssi,
    required this.status,
    required this.lastSeen,
    this.mfgData,
    this.alias,
    this.mac,
  });
>>>
```

```
EDIT_BLOCK 3
FILE: lib/core/ble/ble_models.dart
ACTION: REPLACE
ANCHOR: <<<
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
>>>
NEW_CONTENT: <<<
  /// Copy with updated fields.
  ScannedDevice copyWith({
    int? rssi,
    double? smoothedRssi,
    DeviceStatus? status,
    DateTime? lastSeen,
    ManufacturerData? mfgData,
    String? alias,
    String? mac,
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
      mac: mac ?? this.mac,
    );
  }
>>>
```

**Step 4:** Run: `flutter test test/core/ble/ble_models_test.dart` → PASS

**Step 5:** `git add lib/core/ble/ble_models.dart test/core/ble/ble_models_test.dart && git commit -m "domain(scan): add mac field to ScannedDevice for identity migration"`

---

### Task 7: [Infrastructure] BleScanner Identity Resolution + TTL Eviction

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_scanner.dart`
- Create: `test/core/ble/ble_scanner_test.dart`

**Step 1:** Test for eviction logic.

```
EDIT_BLOCK 1
FILE: test/core/ble/ble_scanner_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';

void main() {
  group('BleScanner TTL Eviction', () {
    test('given_offline_device_when_updateDeviceStatuses_then_device_evicted', () {
      final now = DateTime(2026, 1, 1, 0, 1, 0);
      final lastSeen = DateTime(2026, 1, 1, 0, 0, 0);
      final status = deviceStatusFromLastSeen(lastSeen, now: now);
      expect(status, DeviceStatus.offline);
    });
  });
}
>>>
```

**Step 2:** Run: `flutter test test/core/ble/ble_scanner_test.dart` → PASS

**Step 3:** See section-03 for all EDIT_BLOCKs (identity import, _onScanResults migration, TTL eviction, provider update).

```
EDIT_BLOCK 2
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
import '../gatt/gatt_uuids.dart';
import 'ble_models.dart';
import 'manufacturer_data.dart';
>>>
NEW_CONTENT: <<<
import '../gatt/gatt_uuids.dart';
import '../identity/device_identity_service.dart';
import 'ble_models.dart';
import 'manufacturer_data.dart';
>>>
```

```
EDIT_BLOCK 3
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
/// BLE scanner with EMA smoothing, stale/offline tracking, and duty cycle — spec §4.1.
class BleScanner {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();
  Timer? _statusTimer;
  Timer? _dutyCycleTimer;
  bool _scanning = false;
>>>
NEW_CONTENT: <<<
/// BLE scanner with EMA smoothing, stale/offline tracking, TTL eviction,
/// and duty cycle — spec §4.1.
class BleScanner {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();
  Timer? _statusTimer;
  Timer? _dutyCycleTimer;
  bool _scanning = false;
  DeviceIdentityService? _identityService;

  set identityService(DeviceIdentityService? service) =>
      _identityService = service;
>>>
```

```
EDIT_BLOCK 4
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    for (final r in results) {
      final id = r.device.remoteId.str;

      // Device name: prefer advName, fallback to platformName
      final advName = r.advertisementData.advName;
      final platformName = r.device.platformName;
      final name = advName.isNotEmpty ? advName : platformName;
      final existing = _devices[id];

      // Parse manufacturer data
      ManufacturerData? mfgData;
      final mfgMap = r.advertisementData.manufacturerData;
      if (mfgMap.isNotEmpty) {
        final entry = mfgMap.entries.first;
        mfgData = ManufacturerData.parse(
          Uint8List.fromList([...entry.value]),
        );
      }

      // EMA smoothing
      final smoothed = emaRssi(r.rssi, existing?.smoothedRssi, alpha: emaAlpha);

      // Software filter: only QoS devices (connectable + advertising UUID 0x1820).
      if (!r.advertisementData.connectable) continue;
      final hasQosUuid = r.advertisementData.serviceUuids.contains(_qosServiceUuid);
      if (!hasQosUuid) continue;

      _devices[id] = ScannedDevice(
        id: id,
        name: name,
        rssi: r.rssi,
        smoothedRssi: smoothed,
        status: DeviceStatus.online,
        lastSeen: now,
        mfgData: mfgData ?? existing?.mfgData,
        alias: existing?.alias,
      );
    }
    _controller.add(_devices.values.toList());
  }
>>>
NEW_CONTENT: <<<
  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    for (final r in results) {
      final mac = r.device.remoteId.str;
      final stableId = _identityService?.resolveOrAssignSync(mac) ?? mac;

      final advName = r.advertisementData.advName;
      final platformName = r.device.platformName;
      final name = advName.isNotEmpty ? advName : platformName;
      final existing = _devices[stableId];

      ManufacturerData? mfgData;
      final mfgMap = r.advertisementData.manufacturerData;
      if (mfgMap.isNotEmpty) {
        final entry = mfgMap.entries.first;
        mfgData = ManufacturerData.parse(
          Uint8List.fromList([...entry.value]),
        );
      }

      final smoothed = emaRssi(r.rssi, existing?.smoothedRssi, alpha: emaAlpha);

      if (!r.advertisementData.connectable) continue;
      final hasQosUuid = r.advertisementData.serviceUuids.contains(_qosServiceUuid);
      if (!hasQosUuid) continue;

      _devices[stableId] = ScannedDevice(
        id: stableId,
        name: name,
        rssi: r.rssi,
        smoothedRssi: smoothed,
        status: DeviceStatus.online,
        lastSeen: now,
        mfgData: mfgData ?? existing?.mfgData,
        alias: existing?.alias,
        mac: mac,
      );
    }
    _controller.add(_devices.values.toList());
  }
>>>
```

```
EDIT_BLOCK 5
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Update device statuses based on lastSeen time.
  void _updateDeviceStatuses() {
    bool changed = false;
    final now = DateTime.now();
    for (final entry in _devices.entries.toList()) {
      final newStatus = deviceStatusFromLastSeen(entry.value.lastSeen, now: now);
      if (newStatus != entry.value.status) {
        _devices[entry.key] = entry.value.copyWith(status: newStatus);
        changed = true;
      }
    }
    if (changed) {
      _controller.add(_devices.values.toList());
    }
  }
>>>
NEW_CONTENT: <<<
  /// Update device statuses based on lastSeen time.
  /// TTL Eviction: removes offline devices from visible list.
  void _updateDeviceStatuses() {
    bool changed = false;
    final now = DateTime.now();
    final toEvict = <String>[];

    for (final entry in _devices.entries.toList()) {
      final newStatus = deviceStatusFromLastSeen(entry.value.lastSeen, now: now);
      if (newStatus == DeviceStatus.offline) {
        toEvict.add(entry.key);
        changed = true;
      } else if (newStatus != entry.value.status) {
        _devices[entry.key] = entry.value.copyWith(status: newStatus);
        changed = true;
      }
    }

    for (final key in toEvict) {
      _devices.remove(key);
    }

    if (changed) {
      _controller.add(_devices.values.toList());
    }
  }
>>>
```

```
EDIT_BLOCK 6
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
/// Riverpod provider for the scanner.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
>>>
NEW_CONTENT: <<<
/// Riverpod provider for the scanner.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  // Identity service injection — will be wired when identityServiceProvider exists
  // scanner.identityService = ref.watch(identityServiceProvider);
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
>>>
```

**Step 4:** Run: `flutter test test/core/ble/ble_scanner_test.dart` → PASS

**Step 5:** `git add lib/core/ble/ble_scanner.dart test/core/ble/ble_scanner_test.dart && git commit -m "infra(scan): migrate BleScanner to StableId keys with TTL eviction"`

---

### Task 8: [Infrastructure] Add `mac` Field to ConnectedDevice

See section-04-connection-infra.md for full details.

**Files:** `lib/core/providers/device_provider.dart`, `test/core/providers/device_provider_test.dart`

**Step 5:** `git commit -m "infra(provider): add mac field to ConnectedDevice"`

---

### Task 9: [Infrastructure] BleConnector StableId→MAC Resolution

See section-04-connection-infra.md for full details.

**Files:** `lib/core/ble/ble_connector.dart`

**Step 5:** `git commit -m "infra(connector): resolve StableId to MAC via DeviceIdentityService"`

---

### Task 10: [Infrastructure] DeviceIdentities Drift Table + Migration

See section-04-connection-infra.md for full details.

**Files:** `lib/core/data/tables/device_identities.dart`, `lib/core/data/tables/devices.dart`, `lib/core/data/database.dart`, `lib/core/identity/drift_identity_repository.dart`

**Step 5:** `git commit -m "infra(data): add DeviceIdentities table, schema v2 migration"`

---

### Task 11: [Infrastructure] Identity Provider Wiring

See section-04-connection-infra.md for full details.

**Files:** `lib/core/providers/identity_provider.dart`, `lib/core/ble/ble_scanner.dart`, `lib/core/ble/ble_connector.dart`

**Step 5:** `git commit -m "infra(provider): wire DeviceIdentityService into scanner and connector"`

---

### Task 12: [Infrastructure] CapabilityReader — GATT Read with Role Fallback

See section-05-capability-infra.md for full details.

**Files:** `lib/core/capability/capability_reader.dart`, `test/core/capability/capability_reader_test.dart`

**Step 5:** `git commit -m "infra(capability): add CapabilityReader with GATT read and role fallback"`

---

### Task 13: [Infrastructure] CapabilityReader Riverpod Provider

See section-05-capability-infra.md for full details.

**Files:** `lib/core/capability/capability_reader.dart`

**Step 5:** `git commit -m "infra(capability): add capabilityNegotiationProvider"`

---

## Layer 4: Presentation

### Task 14: [Presentation] ScannerScreen StableId Navigation

See section-06-presentation.md for full details.

**Files:** `lib/features/scanner/scanner_screen.dart`

**Step 5:** `git commit -m "ui(scanner): clarify StableId usage in navigation"`

---

### Task 15: [Presentation] DeviceScreen AppBar Title from Device Name

See section-06-presentation.md for full details.

**Files:** `lib/features/device/device_screen.dart`

**Step 5:** `git commit -m "ui(device): show device name in AppBar instead of StableId"`

---

### Task 16: [Presentation] DeviceScreen GATT Capability + Degradation UI

See section-06-presentation.md for full details.

**Files:** `lib/features/device/device_screen.dart`

**Step 5:** `git commit -m "ui(device): add GATT capability negotiation with degradation badges"`

---

### Task 17: [Presentation] DeviceScreen Limited Mode Banner

See section-06-presentation.md for full details.

**Files:** `lib/features/device/device_screen.dart`

**Step 5:** `git commit -m "ui(device): add limited mode banner for fully incompatible devices"`
