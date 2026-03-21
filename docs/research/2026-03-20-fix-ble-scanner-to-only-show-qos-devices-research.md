# Research Brief: Fix BLE Scanner to Only Show QoS Devices
**Date:** 2026-03-20
**Task:** Fix BLE scanner to only show QoS devices (GW and ED). (A1) Add withServices UUID filter to BLE scanner with UUID 0x1820. (A2) Fix manufacturer_data.dart role values to match firmware adv_mfg.h — swap roleEndDevice/roleGateway.
**Domain Model:** docs/domain/2026-03-20-fix-ble-scanner-to-only-show-qos-devices-domain-model.md

---

## 1. Existing Code Map

### BLE Scanner — Missing withServices Filter
- **Current location:** `lib/core/ble/ble_scanner.dart:L113-120` (`_startContinuousScan`), `L128-136` (`_dutyCycleTick`)
- **Current behavior:** Calls `FlutterBluePlus.startScan()` with NO `withServices` parameter — all connectable BLE devices pass through, not just QoS devices. Comment at L115 says "No UUID filter".
- **Key functions:** `_startContinuousScan()`, `_dutyCycleTick()` — both call `startScan()` without filtering
- **Config source:** `lib/core/gatt/gatt_uuids.dart:L7` — `serviceQos = '00001820-0000-1000-8000-00805f9b34fb'` (already defined, already imported at `ble_scanner.dart:L7`, but NOT used)

### ManufacturerData — Swapped Role Constants
- **Current location:** `lib/core/ble/manufacturer_data.dart:L8-9`
- **Current behavior:** `roleEndDevice = 0x01`, `roleGateway = 0x02` — **SWAPPED** vs firmware (`ADV_MFG_ROLE_GW=0x01`, `ADV_MFG_ROLE_ED=0x02`)
- **Key functions:** `ManufacturerData.parse(Uint8List)` at L33; `isGateway` getter at L26; `isEndDevice` getter at L27
- **Config source:** Firmware `adv_mfg.h` defines `ADV_MFG_ROLE_GW=0x01`, `ADV_MFG_ROLE_ED=0x02`

### GattUuids — QoS Service UUID (SSOT)
- **Current location:** `lib/core/gatt/gatt_uuids.dart:L7`
- **Current behavior:** Defines `serviceQos = '00001820-0000-1000-8000-00805f9b34fb'` — correct value, no duplicates in codebase
- **Key functions:** Static constant, consumed by import

### Downstream Consumers
- **ScannedDevice:** `lib/core/ble/ble_models.dart:L60-61` — `roleLabel` getter uses `isGateway`/`isEndDevice` (will auto-correct after constant swap)
- **CapabilityRegistry:** `lib/core/capability/capability_registry.dart:L38-45` — `fallbackForRole()` switch reads `ManufacturerData.roleGateway`/`roleEndDevice` constants (will auto-correct after constant swap)

---

## 2. Caller / Dependency Map

| Source | Calls | Via |
|--------|-------|-----|
| `ble_scanner.dart:L71` | `ManufacturerData.parse()` | direct import |
| `ble_scanner.dart:L117` | `FlutterBluePlus.startScan()` | direct (no withServices) |
| `ble_scanner.dart:L129` | `FlutterBluePlus.startScan()` | direct (no withServices) |
| `ble_scanner.dart:L7` | `GattUuids` | import (unused for scanning) |
| `ble_models.dart:L60-61` | `ManufacturerData.isGateway`/`isEndDevice` | via `ScannedDevice.mfgData` |
| `capability_registry.dart:L38,43` | `ManufacturerData.roleGateway`/`roleEndDevice` | direct import |
| `scanner_screen.dart:L9` | `BleScanner` | direct import |

---

## 3. Config & SSOT Analysis

| Value | SSOT Location | Current Value | Duplicates/Hardcodes |
|-------|--------------|---------------|---------------------|
| QoS Service UUID | `gatt_uuids.dart:L7` | `00001820-...` | No duplicates; not yet used by scanner |
| roleEndDevice | `manufacturer_data.dart:L8` | `0x01` (**WRONG — should be 0x02**) | Hardcoded in `manufacturer_data_test.dart:L22,25`; `capability_registry_test.dart:L39` |
| roleGateway | `manufacturer_data.dart:L9` | `0x02` (**WRONG — should be 0x01**) | Hardcoded in `manufacturer_data_test.dart:L9,14`; `capability_registry_test.dart:L34` |
| roleUnprovisioned | `manufacturer_data.dart:L7` | `0x00` | OK — no change needed |
| roleCentralController | `manufacturer_data.dart:L10` | `0x04` | OK — no change needed |
| flutter_blue_plus version | `pubspec.yaml:L35` | `^1.35.0` | Supports `withServices` parameter |

---

## 4. External References

| Topic | Industry Standard | Our Implementation | Gap |
|-------|------------------|-------------------|-----|
| Scan UUID filter | FlutterBluePlus: `startScan(withServices: [Guid("1820")])` | No filter — all connectable devices shown | **YES** |
| GW role constant | Firmware: `ADV_MFG_ROLE_GW = 0x01` | `roleGateway = 0x02` | **YES — swapped** |
| ED role constant | Firmware: `ADV_MFG_ROLE_ED = 0x02` | `roleEndDevice = 0x01` | **YES — swapped** |
| UUID 0x1820 | Bluetooth SIG: assigned to IPSP (Internet Protocol Support Service) | Used as "QoS Service" | Intentional repurpose — low risk for dev |
| Mfg data CID handling | First 2 bytes = Company ID (SIG spec) | FBP strips CID; parser reads payload only | Correct for FBP API |
| Android scan limits | Max 5 scans per 30 seconds | Not currently rate-limited | Not in scope |

---

## 5. Cross-cutting Concerns

- **Config imported but unused:** `ble_scanner.dart:L7` imports `gatt_uuids.dart` (Code Map + Config Worker both confirm), but the `serviceQos` UUID is never passed to `startScan()`. The wiring is half-done.
- **Hardcoded test values mirror the bug:** Both `manufacturer_data_test.dart` and `capability_registry_test.dart` hardcode role bytes (`0x01`/`0x02`) matching the wrong constants rather than referencing `ManufacturerData.roleGateway`/`.roleEndDevice`. After the constant swap, **4 test files need updates** (Code Map found 2 test files, Config Worker found the additional `capability_registry_test.dart`).
- **Downstream auto-correction:** `isGateway`/`isEndDevice` getters and `CapabilityRegistry.fallbackForRole()` all use the SSOT constants — they will auto-correct after the swap with no code changes needed in production code.
- **Firmware advertising prerequisite (External Worker):** Old comment at `ble_scanner.dart:L115` says "firmware may not advertise service UUID in adv data." If firmware hasn't been updated to include `0x1820` in its advertising packets, the `withServices` filter will show **zero devices**. This is a critical deployment dependency.
- **UUID 0x1820 repurpose risk (External Worker):** UUID 0x1820 is Bluetooth SIG-assigned to IPSP. Using it as "QoS Service" is common in development but could conflict during Bluetooth qualification. Low priority for now.
- **No contradictions between workers** — all three agree on file paths, line numbers, and the nature of both bugs.

---

## 6. Risks & Constraints

- **CRITICAL: Firmware must advertise UUID 0x1820** in its service UUIDs for the `withServices` filter to work. If firmware doesn't include it, scanner will find zero devices after this change. Verify firmware advertising data before deploying.
- **Test breakage scope:** At least 3 test files need role value updates (`manufacturer_data_test.dart`, `ble_models_test.dart`, `capability_registry_test.dart`). Missing any will cause CI failure.
- **No scanner unit tests exist** (`ble_scanner_test.dart` does not exist) — the `withServices` change cannot be verified by automated tests without manual testing or mocking FlutterBluePlus.
- **Android scan rate limit:** 5 scans per 30 seconds — not directly relevant but worth noting if scan behavior changes.
- **FlutterBluePlus API:** `withServices` accepts `List<Guid>` — confirmed from package conventions but not verified against FBP source code. Medium confidence.

---

## 7. Recommendations for Plan

- **Swap role constants first** (A2) before adding UUID filter (A1) — the constant swap is self-contained and testable
- **Update ALL test files with hardcoded role values:** `manufacturer_data_test.dart`, `ble_models_test.dart`, `capability_registry_test.dart`
- **Use `ManufacturerData.roleGateway`/`.roleEndDevice` constants in tests** instead of raw hex — prevents future drift
- **Add `withServices: [Guid(GattUuids.serviceQos)]`** to BOTH `_startContinuousScan()` AND `_dutyCycleTick()` in `ble_scanner.dart`
- **Verify firmware advertises 0x1820** before merging — add a note/TODO if firmware status is unknown

### Files that MUST be modified:
1. `lib/core/ble/manufacturer_data.dart` — swap roleEndDevice to `0x02`, roleGateway to `0x01`
2. `lib/core/ble/ble_scanner.dart` — add `withServices: [Guid(GattUuids.serviceQos)]` to both `startScan()` calls
3. `test/core/ble/manufacturer_data_test.dart` — update role byte values and assertions
4. `test/core/ble/ble_models_test.dart` — update `role: 2` → `role: 1` for GW fixture
5. `test/core/capability/capability_registry_test.dart` — swap hardcoded `0x02`/`0x01` for GW/ED

### Files that MUST NOT be modified:
- `lib/core/gatt/gatt_uuids.dart` — `serviceQos` UUID is already correct
- `lib/core/ble/ble_models.dart` — uses getters, auto-corrects
- `lib/core/capability/capability_registry.dart` — uses constants, auto-corrects

---

## 8. Knowledge Graph

### Key Entities
- `BleScanner` (class) — BLE scan orchestrator, missing withServices filter
- `ManufacturerData` (class) — parses BLE manufacturer advertising data, has swapped role constants
- `GattUuids.serviceQos` (config) — QoS Service UUID `0x1820`, SSOT, already defined and imported
- `CapabilityRegistry` (class) — downstream consumer of role constants, will auto-correct
- `ScannedDevice` (class) — downstream consumer of role getters, will auto-correct
- `firmware.adv_mfg_roles` (external) — firmware source of truth for role values (GW=0x01, ED=0x02)
- `flutter_blue_plus.withServices` (external) — standard scan filter API

### Key Relation Chains
1. `firmware.adv_mfg_roles` → causes → `ManufacturerData` role constants mismatch → affects → `isGateway`/`isEndDevice` getters → affects → `ScannedDevice.roleLabel` + `CapabilityRegistry.fallbackForRole`
2. `GattUuids.serviceQos` → defines → UUID for `BleScanner` → (missing link) → `FlutterBluePlus.startScan(withServices:)` — the connection is imported but not wired
3. `ManufacturerData.roleGateway`/`.roleEndDevice` → hardcoded in → `manufacturer_data_test.dart` + `capability_registry_test.dart` → validated by → CI (`flutter test`)

### Uncertainties / Conflicts
- **Medium confidence:** Whether firmware currently advertises UUID 0x1820 in its advertising packets (old comment suggests it may not)
- **Medium confidence:** FlutterBluePlus `withServices` parameter type is `List<Guid>` (inferred from conventions, not source-verified)
- **Low priority:** UUID 0x1820 is SIG-assigned to IPSP — repurposing is intentional but may matter for Bluetooth qualification
- **No worker conflicts** — all three workers agree on all facts

### Merged Graph
No `merged_graph.json` was produced by `tools/merge_research_graph.py`. Graph data is synthesized from worker report JSON extractions above.
