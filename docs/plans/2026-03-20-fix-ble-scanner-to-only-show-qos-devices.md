# Fix BLE Scanner to Only Show QoS Devices — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the BLE Discovery Context so the BleScanner only shows QoS devices by applying a withServices UUID filter (0x1820) and correcting the ManufacturerData role constants to match firmware adv_mfg.h (Gateway=0x01, EndDevice=0x02).
**Bounded Context(s):** BLE Discovery Context, GATT Protocol Context
**Architecture:** Domain layer fixes first (swap ManufacturerData role constants), then Infrastructure layer (add withServices filter to BleScanner's FlutterBluePlus.startScan calls). GattUuids.serviceQos already exists as SSOT — no new constants needed. Downstream consumers (ScannedDevice, CapabilityRegistry) auto-correct via SSOT constants.
**Tech Stack:** Flutter/Dart, FlutterBluePlus, flutter_test, Riverpod
**Domain Model:** docs/domain/2026-03-20-fix-ble-scanner-to-only-show-qos-devices-domain-model.md
**Research Brief:** docs/research/2026-03-20-implement-ble-qos-mobile-app-per-design--research.md
**Assumptions:**
- FlutterBluePlus `startScan(withServices:)` accepts `List<Guid>` — confirmed from package conventions
- Firmware has been updated to advertise UUID 0x1820 in its service UUIDs (prerequisite for withServices filter to work)

**Propagation Checklist:**
- [x] Files sharing ManufacturerData role constants: `lib/core/ble/manufacturer_data.dart` (SSOT), `test/core/ble/manufacturer_data_test.dart`, `test/core/ble/ble_models_test.dart`, `test/core/capability/capability_registry_test.dart` (all hardcode role bytes)
- [x] Config keys affected: `ManufacturerData.roleGateway` (0x02→0x01), `ManufacturerData.roleEndDevice` (0x01→0x02)
- [x] Subprocess callers that need update: `BleScanner._startContinuousScan()` (L117), `BleScanner._dutyCycleTick()` (L129) — both need `withServices` param
- [x] Files that auto-correct (NO changes needed): `lib/core/ble/ble_models.dart`, `lib/core/capability/capability_registry.dart`

**EDIT_BLOCK Validation:**
- [x] Every ANCHOR verified unique in target file (post prior edits)
- [x] Cross-task anchor dependencies noted
- [x] CREATE_FILE provides complete file content
- [x] REPLACE anchors include ALL lines being removed
- [x] No EDIT_BLOCK relies on nearest-match or semantic search

---

## Layer 1: Domain

### Task 1: Fix ManufacturerData Role Constants to Match Firmware

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Modify: `lib/core/ble/manufacturer_data.dart`

**Step 1: Write the failing test (BDD format)**

No new test file needed — existing tests in `test/core/ble/manufacturer_data_test.dart` will fail after the constant swap because they hardcode the old (wrong) role byte values. The test updates happen in Task 2.

This task swaps the SSOT constants. After this task, existing tests WILL fail (expected — fixed in Task 2).

**Step 2: Verify current tests pass (pre-swap baseline)**
Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: PASS (tests match old wrong values)

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/ble/manufacturer_data.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Role constants matching firmware PEER_ROLE definitions.
  static const int roleUnprovisioned = 0x00;
  static const int roleEndDevice = 0x01;
  static const int roleGateway = 0x02;
>>>
NEW_CONTENT: <<<
  /// Role constants matching firmware adv_mfg.h definitions.
  /// ADV_MFG_ROLE_GW=0x01, ADV_MFG_ROLE_ED=0x02.
  static const int roleUnprovisioned = 0x00;
  static const int roleGateway = 0x01;
  static const int roleEndDevice = 0x02;
>>>
NOTE: Swap roleEndDevice/roleGateway to match firmware adv_mfg.h. Gateway=0x01, EndDevice=0x02. Order changed to match ascending firmware values.
```

**Step 4: Verify existing tests now fail (constants swapped, tests still have old values)**
Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: FAIL (tests hardcode old role bytes — fixed in Task 2)

**Step 5: Commit**
```
git add lib/core/ble/manufacturer_data.dart && git commit -m "domain(ble-discovery): fix ManufacturerData role constants to match firmware adv_mfg.h

roleGateway: 0x02 → 0x01 (ADV_MFG_ROLE_GW)
roleEndDevice: 0x01 → 0x02 (ADV_MFG_ROLE_ED)"
```

---

### Task 2: Update ManufacturerData Tests for Correct Role Values

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Modify: `test/core/ble/manufacturer_data_test.dart`

**Step 1: Write the failing test (BDD format)**

Update existing tests to use correct firmware role bytes. GW payload byte = 0x01, ED payload byte = 0x02.

**Step 2: Run to verify tests currently fail (from Task 1 constant swap)**
Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: test/core/ble/manufacturer_data_test.dart
ACTION: REPLACE
ANCHOR: <<<
    test('parse valid GW payload', () {
      // protocol=1, role=2(GW), network_id=0x0001, ed_count=3, ha_role=1(active)
      final bytes = Uint8List.fromList([1, 2, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.protocolVersion, 1);
      expect(data.role, 2);
      expect(data.networkId, 1);
      expect(data.edCount, 3);
      expect(data.haRole, 1);
    });
>>>
NEW_CONTENT: <<<
    test('parse valid GW payload', () {
      // protocol=1, role=0x01(GW per firmware ADV_MFG_ROLE_GW), network_id=0x0001, ed_count=3, ha_role=1(active)
      final bytes = Uint8List.fromList([1, ManufacturerData.roleGateway, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.protocolVersion, 1);
      expect(data.role, ManufacturerData.roleGateway);
      expect(data.networkId, 1);
      expect(data.edCount, 3);
      expect(data.haRole, 1);
    });
>>>
NOTE: Use ManufacturerData.roleGateway constant instead of hardcoded 2. GW role is now 0x01.
```

```
EDIT_BLOCK 2
FILE: test/core/ble/manufacturer_data_test.dart
ACTION: REPLACE
ANCHOR: <<<
    test('parse valid ED payload (shorter)', () {
      // protocol=1, role=1(ED), network_id=0x0002
      final bytes = Uint8List.fromList([1, 1, 2, 0]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.role, 1);
      expect(data.networkId, 2);
      expect(data.edCount, isNull);
    });
>>>
NEW_CONTENT: <<<
    test('parse valid ED payload (shorter)', () {
      // protocol=1, role=0x02(ED per firmware ADV_MFG_ROLE_ED), network_id=0x0002
      final bytes = Uint8List.fromList([1, ManufacturerData.roleEndDevice, 2, 0]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.role, ManufacturerData.roleEndDevice);
      expect(data.networkId, 2);
      expect(data.edCount, isNull);
    });
>>>
NOTE: Use ManufacturerData.roleEndDevice constant instead of hardcoded 1. ED role is now 0x02.
```

```
EDIT_BLOCK 3
FILE: test/core/ble/manufacturer_data_test.dart
ACTION: REPLACE
ANCHOR: <<<
    test('isGateway returns true for role 2', () {
      final bytes = Uint8List.fromList([1, 2, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes)!;
      expect(data.isGateway, isTrue);
      expect(data.isEndDevice, isFalse);
    });
>>>
NEW_CONTENT: <<<
    test('given GW role byte when parsed then isGateway returns true', () {
      final bytes = Uint8List.fromList([1, ManufacturerData.roleGateway, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes)!;
      expect(data.isGateway, isTrue);
      expect(data.isEndDevice, isFalse);
    });

    test('given ED role byte when parsed then isEndDevice returns true', () {
      final bytes = Uint8List.fromList([1, ManufacturerData.roleEndDevice, 2, 0]);
      final data = ManufacturerData.parse(bytes)!;
      expect(data.isEndDevice, isTrue);
      expect(data.isGateway, isFalse);
    });
>>>
NOTE: Rename to BDD format, use constants, add symmetric ED test.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: PASS

**Step 5: Commit**
```
git add test/core/ble/manufacturer_data_test.dart && git commit -m "domain(ble-discovery): update ManufacturerData tests for correct firmware role values

Use ManufacturerData.roleGateway/roleEndDevice constants instead of hardcoded bytes.
GW=0x01, ED=0x02 per firmware adv_mfg.h."
```

---

### Task 3: Update ble_models_test for Correct Gateway Role Byte

**Layer:** Domain
**DDD Pattern:** Entity
**Files:**
- Modify: `test/core/ble/ble_models_test.dart`

**Step 1: Write the failing test (BDD format)**

The existing test at L42-60 creates a `ManufacturerData(role: 2, ...)` for a GW fixture. After Task 1's constant swap, `role: 2` now means EndDevice, so `isGateway` returns false. Update to use the constant.

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/ble_models_test.dart`
Expected: FAIL (the `isGateway` assertion at L59 will fail because role: 2 is now ED)

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: test/core/ble/ble_models_test.dart
ACTION: REPLACE
ANCHOR: <<<
    test('stores ManufacturerData field', () {
      final mfg = ManufacturerData(
        protocolVersion: 1,
        role: 2,
        networkId: 1,
        edCount: 3,
        haRole: 1,
      );
>>>
NEW_CONTENT: <<<
    test('given ScannedDevice with GW ManufacturerData when accessed then mfgData is present', () {
      final mfg = ManufacturerData(
        protocolVersion: 1,
        role: ManufacturerData.roleGateway,
        networkId: 1,
        edCount: 3,
        haRole: 1,
      );
>>>
NOTE: Use ManufacturerData.roleGateway constant (0x01) instead of hardcoded 2. Rename to BDD.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_models_test.dart`
Expected: PASS

**Step 5: Commit**
```
git add test/core/ble/ble_models_test.dart && git commit -m "domain(ble-discovery): fix ble_models_test GW role to use ManufacturerData.roleGateway constant"
```

---

### Task 4: Update capability_registry_test for Correct Role Values

**Layer:** Domain
**DDD Pattern:** DomainService
**Files:**
- Modify: `test/core/capability/capability_registry_test.dart`

**Step 1: Write the failing test (BDD format)**

The existing tests at L33-41 hardcode `0x02` for GW and `0x01` for ED in `fallbackForRole()` calls. After the constant swap, these are now reversed.

**Step 2: Run to verify it fails**
Run: `flutter test test/core/capability/capability_registry_test.dart`
Expected: FAIL (fallbackForRole(0x02) now returns ED capabilities, not GW)

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: test/core/capability/capability_registry_test.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'package:ble_qos_app/core/capability/capability_registry.dart';
>>>
NEW_CONTENT: <<<
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
>>>
NOTE: Import ManufacturerData to reference role constants instead of hardcoded values.
```

```
EDIT_BLOCK 2
FILE: test/core/capability/capability_registry_test.dart
ACTION: REPLACE
ANCHOR: <<<
    test('fallback capabilities for gateway role', () {
      final caps = CapabilityRegistry.fallbackForRole(0x02); // ROLE_GATEWAY
      expect(caps.map((c) => c.id), containsAll(['qos_monitor', 'ed_roster', 'ha_runtime']));
    });

    test('fallback capabilities for end_device role', () {
      final caps = CapabilityRegistry.fallbackForRole(0x01); // ROLE_END_DEVICE
      expect(caps.map((c) => c.id), contains('qos_monitor'));
    });
>>>
NEW_CONTENT: <<<
    test('given gateway role when fallback then returns GW capabilities', () {
      final caps = CapabilityRegistry.fallbackForRole(ManufacturerData.roleGateway);
      expect(caps.map((c) => c.id), containsAll(['qos_monitor', 'ed_roster', 'ha_runtime']));
    });

    test('given end device role when fallback then returns ED capabilities', () {
      final caps = CapabilityRegistry.fallbackForRole(ManufacturerData.roleEndDevice);
      expect(caps.map((c) => c.id), contains('qos_monitor'));
    });
>>>
NOTE: Use ManufacturerData constants instead of hardcoded 0x02/0x01. Rename to BDD.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/capability/capability_registry_test.dart`
Expected: PASS

**Step 5: Commit**
```
git add test/core/capability/capability_registry_test.dart && git commit -m "domain(ble-discovery): fix capability_registry_test to use ManufacturerData role constants"
```

---

## Layer 3: Infrastructure

### Task 5: Add withServices QoS UUID Filter to BleScanner

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_scanner.dart`

**Step 1: Write the failing test (BDD format)**

No automated test — BleScanner has no unit test file and requires mocking FlutterBluePlus (out of scope per research brief). Verified by manual scan testing.

Add a TODO comment for future scanner test coverage.

**Step 2: Skip (no automated test)**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
  void _startContinuousScan() {
    _scanning = true;
    // No UUID filter — firmware may not advertise service UUID in adv data.
    // Devices identified by name prefix or manufacturer data instead.
    FlutterBluePlus.startScan(
      androidUsesFineLocation: true,
    );
  }
>>>
NEW_CONTENT: <<<
  void _startContinuousScan() {
    _scanning = true;
    // Filter by QoS Service UUID (0x1820) — only show QoS GW and ED devices.
    FlutterBluePlus.startScan(
      withServices: [Guid(GattUuids.serviceQos)],
      androidUsesFineLocation: true,
    );
  }
>>>
NOTE: Add withServices filter using GattUuids.serviceQos (already imported at L7). Removes stale comment about firmware not advertising UUID.
```

```
EDIT_BLOCK 2
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
  void _dutyCycleTick() {
    FlutterBluePlus.startScan(
      androidUsesFineLocation: true,
      timeout: scanWindow,
    );
>>>
NEW_CONTENT: <<<
  void _dutyCycleTick() {
    FlutterBluePlus.startScan(
      withServices: [Guid(GattUuids.serviceQos)],
      androidUsesFineLocation: true,
      timeout: scanWindow,
    );
>>>
NOTE: Add same withServices filter to duty cycle scan path. Both scan entry points must filter identically.
```

**Step 4: Run all tests to verify no regressions**
Run: `flutter test`
Expected: PASS (scanner change is not covered by unit tests but must not break other tests)

**Step 5: Commit**
```
git add lib/core/ble/ble_scanner.dart && git commit -m "infra(ble-discovery): add withServices QoS UUID filter to BleScanner

Both _startContinuousScan and _dutyCycleTick now filter by
GattUuids.serviceQos (0x1820) via FlutterBluePlus.startScan(withServices:).
Only QoS GW and ED devices will appear in scan results.

NOTE: Requires firmware to advertise UUID 0x1820 in advertising packets."
```

---

## Verification

### Final Smoke Test

After all 5 tasks are complete, run the full test suite:

```
flutter test
```

Expected: ALL PASS

### Manual Verification Checklist
- [ ] `ManufacturerData.roleGateway` == `0x01` (matches firmware `ADV_MFG_ROLE_GW`)
- [ ] `ManufacturerData.roleEndDevice` == `0x02` (matches firmware `ADV_MFG_ROLE_ED`)
- [ ] `BleScanner._startContinuousScan()` includes `withServices: [Guid(GattUuids.serviceQos)]`
- [ ] `BleScanner._dutyCycleTick()` includes `withServices: [Guid(GattUuids.serviceQos)]`
- [ ] No hardcoded role byte values remain in test files (all use `ManufacturerData.roleGateway`/`.roleEndDevice`)
- [ ] `GattUuids.serviceQos` unchanged (`00001820-0000-1000-8000-00805f9b34fb`)
- [ ] Firmware advertises UUID 0x1820 in advertising data (deployment prerequisite)
