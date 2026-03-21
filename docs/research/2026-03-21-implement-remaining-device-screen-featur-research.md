# Research Brief: Implement Remaining Device Screen Features
**Date:** 2026-03-21
**Task:** Implement remaining Device Screen features per Design Spec: (1) Provisioning ROLE write — wire up provisioning_screen.dart form submit to GATT write ROLE characteristic (0x2A1F) with uint8 value, show confirmation dialog, handle device reboot after write. (2) HA Tab — subscribe to HA_HB characteristic (6f8a9c15) notify, parse 21-byte heartbeat payload, display HA role (active/standby), epoch, heartbeat count, last failover event. (3) Admin Tab ENG_UNLOCK — implement engineer PIN entry dialog, write ENG_UNLOCK characteristic (6f8a9c11) with ASCII PIN, handle success/failure response. (4) Admin Tab CMD reboot — implement CMD 0x01 reboot with confirmation dialog, requires ENG_UNLOCK first. (5) Admin Tab MODE/ROLE write — implement MODE and ROLE write with dropdown selector and confirmation.
**Domain Model:** docs/domain/2026-03-21-implement-remaining-device-screen-featur-domain-model.md

---

## 1. Existing Code Map

### Provisioning ROLE Write
- **Current location:** `lib/features/provisioning/provisioning_screen.dart:L165-196`
- **Current behavior:** `_onWriteRole()` shows a confirmation dialog but has `// TODO: Write ROLE characteristic via GATT` — GATT write is not connected. Form has hardcoded string `_roleOptions` (`'Gateway'`, etc.) with no mapping to uint8 values.
- **Key functions:** `_onWriteRole()` (stub), needs `BleGatt.write(GattUuids.role, [uint8Value])`
- **Config source:** `lib/core/gatt/gatt_uuids.dart:L13` — `GattUuids.role = '00002a1f-...'`
- **Blocker:** ProvisioningScreen is a plain `StatefulWidget` — must convert to `ConsumerStatefulWidget` for Riverpod `ref` access to `BleConnector`/`AuthSession`.

### HA Tab (Heartbeat Subscribe)
- **Current location:** `lib/features/device/ha/ha_tab.dart:L6-58`
- **Current behavior:** Static placeholder `StatelessWidget` with hardcoded `'--'` values. No GATT subscription, no import of `BleGatt` or `GattUuids`.
- **Key functions:** None implemented — needs subscribe to HA_HB notify, parse with `HaHeartbeat.fromBytes()`
- **Config source:** `GattUuids.haHb` — **MISSING** from `lib/core/gatt/gatt_uuids.dart` (must add `6f8a9c15-2c1a-4b6f-8a11-8ddc1f4e7b25`)

### Admin Tab (ENG_UNLOCK, CMD, MODE/ROLE)
- **Current location:** `lib/features/device/admin/admin_tab.dart:L7-86`
- **Current behavior:** 5 TODO stubs: ENG_UNLOCK (L30), CMD console (L42), GW_CFG editor (L54), PIN mgmt (L64), MODE/ROLE write (L79) — all are empty `onTap` handlers.
- **Key functions:** All stubs — needs `BleGatt.write()` for each operation
- **Config source:** `GattUuids.engUnlock` at `gatt_uuids.dart:L23`, `GattUuids.cmd` at `L14`, `GattUuids.mode` at `L12`, `GattUuids.role` at `L13`

### GATT Infrastructure (Existing, Reusable)
- **BleGatt:** `lib/core/ble/ble_gatt.dart:L11-66` — `read()`, `write()`, `subscribe()` APIs
- **GattUuids:** `lib/core/gatt/gatt_uuids.dart:L3-28` — SSOT for UUIDs (missing `haHb`)
- **gatt_structs:** `lib/core/gatt/gatt_structs.dart:L1-233` — codec classes (`QosStatus`, `QosCtrl`, etc.) — needs new `HaHeartbeat` class
- **_gattNotifyStream:** `lib/core/providers/metrics_provider.dart:L15-30` — reusable subscribe+parse factory pattern for HA heartbeat
- **PermissionGuard:** `lib/core/auth/permission_guard.dart:L5-39` — already has `GattAction.mode`, `.role`, `.engUnlock`, `.cmdReboot`
- **AuthSession:** `lib/core/auth/auth_session.dart:L4-80` — `elevate(AuthRole.engineer)` for ENG_UNLOCK success
- **ManufacturerData:** `lib/core/ble/manufacturer_data.dart:L8-11` — role constants (GW=0x01, ED=0x02, CC=0x04)

### Reference Pattern (ControlTab)
- **Location:** `lib/features/device/control/control_tab.dart:L84-116`
- **Pattern:** `_writeCtrl()` — permission-gated GATT write with snackbar feedback. This is the **canonical pattern** for all new GATT write operations.

---

## 2. Caller / Dependency Map

| Source | Calls | Via |
|--------|-------|-----|
| `provisioning_screen.dart:L190` | GATT write (TODO) | needs `BleGatt.write(GattUuids.role, ...)` |
| `device_screen.dart:L143` | `HaTab(deviceId:)` | direct import `ha/ha_tab.dart` |
| `device_screen.dart:L98` | `AdminTab(deviceId:)` | direct import `admin/admin_tab.dart` |
| `control_tab.dart:L109` | `BleGatt.write(GattUuids.ctrl, ...)` | direct import — **reference pattern** |
| `control_tab.dart:L89` | `PermissionGuard.canWrite(role, GattAction.ctrl)` | direct import |
| `control_tab.dart:L85` | `ref.read(authSessionProvider)` | via `auth_provider` |
| `metrics_provider.dart:L34` | `_gattNotifyStream(ref, charUuid: GattUuids.status, ...)` | factory pattern |
| `main.dart:L9` | `ProvisioningScreen` | direct import |
| `auth_provider.dart:L7` | `AuthSession()` | creates singleton |
| `permission_guard.dart:L29` | `AuthRole.engineer` check | import `auth_session.dart` |
| `capability_registry.dart:L36` | `ManufacturerData.roleGateway` | role constant consumer |

---

## 3. Config & SSOT Analysis

| Value | SSOT Location | Current Value | Duplicates/Hardcodes |
|-------|--------------|---------------|---------------------|
| ROLE UUID | `gatt_uuids.dart:L13` | `00002a1f-...` | None |
| MODE UUID | `gatt_uuids.dart:L12` | `00002a1e-...` | None |
| CMD UUID | `gatt_uuids.dart:L14` | `00002a20-...` | None |
| ENG_UNLOCK UUID | `gatt_uuids.dart:L23` | `6f8a9c11-...` | None |
| HA_HB UUID | **MISSING** | Should be `6f8a9c15-2c1a-4b6f-8a11-8ddc1f4e7b25` | Only in domain model doc |
| Role GW value | `manufacturer_data.dart:L9` | `0x01` | `provisioning_screen.dart:L22` has string `'Gateway'` without uint8 mapping |
| Role ED value | `manufacturer_data.dart:L10` | `0x02` | Same — no mapping in provisioning |
| Role CC value | `manufacturer_data.dart:L11` | `0x04` | Same |
| ENG PIN length | domain model only | 8 chars ASCII | Not codified anywhere in source |
| HA_HB payload size | domain model only | 21 bytes | Not codified — needs `HaHeartbeat.size = 21` in `gatt_structs.dart` |
| CMD reboot opcode | domain model only | `0x01` | Not defined as a constant in source code |
| Auth idle timeout (eng) | `auth_session.dart:L12` | 5 min | None |
| Auth absolute timeout (eng) | `auth_session.dart:L16` | 4 hr | None |

---

## 4. External References

| Topic | Industry Standard | Our Implementation | Gap |
|-------|------------------|-------------------|-----|
| GATT write type for config | Write-with-response (Punch Through) | `BleGatt.write()` uses default write-with-response | NO |
| BLE byte order | Little-endian per BT Core Spec (Nordic DevZone) | `Endian.little` in all `fromBytes`/`toBytes` | NO |
| BLE security / auth | Layered: BLE pairing (link) + app-level PIN (SidekickInteractive) | `PermissionGuard` + `ENG_UNLOCK` PIN design | NO |
| Provisioning pattern | Form → confirm → write → process → reboot → close() (NovelBits) | Confirm dialog exists, but no GATT write or disconnect handling | YES |
| Post-reboot navigation | `close()` + navigate away (Punch Through) | Not implemented | YES |
| HA_HB UUID | Must be defined in UUID registry | Missing from `GattUuids` | YES |
| HaHeartbeat codec | Fixed-size struct with size validation | No `HaHeartbeat` class exists | YES |
| ENG_UNLOCK PIN validation | 8-char ASCII with rate limiting / lockout | No validation in code, unclear if firmware enforces lockout | YES |
| Disconnect guard on subscribe | Register cancel guard before enabling notify | `BleGatt.subscribe()` does this correctly | NO |

---

## 5. Cross-cutting Concerns

### Config-Code Mismatches
- **Role string→uint8 mapping gap:** `ManufacturerData` (SSOT) defines role constants (GW=0x01, ED=0x02, CC=0x04) but `provisioning_screen.dart:L22` uses string `_roleOptions` (`'Gateway'`, `'End Device'`, `'Central Controller'`) with no mapping to uint8 values. A `roleFromString()` method or role map should be added to `ManufacturerData` to avoid hardcoding.
- **CMD reboot opcode `0x01`** is defined only in the domain model — not codified as a constant anywhere in source code. Should be a constant in `gatt_structs.dart` or a new `CmdCode` class.
- **ENG PIN length (8 chars)** is defined only in the domain model — not validated or codified in source. Should be a constant for validation.

### Industry Standard vs. Current Behavior
- **Post-reboot disconnect handling:** Industry pattern (Punch Through, NovelBits) recommends `close()` + navigate back after provisioning write. Provisioning screen has no disconnect or navigation logic.
- **PIN brute-force protection:** Best practice suggests rate limiting / lockout after N failures. Domain model mentions "remaining attempts" in `EngUnlockFailed` event but unclear if firmware enforces this.

### Test Coverage Gaps
- **No tests exist** for `HaTab`, `AdminTab`, or `DeviceScreen` GATT integration
- **No `HaHeartbeat` codec test** exists (must be added to `test/gatt_structs_test.dart`)
- **No GATT write test** for `ProvisioningScreen` (existing tests are UI rendering only)
- **No mock-based write/subscribe test** for `BleGatt` (`test/core/ble/ble_gatt_test.dart` has minimal signature test only)

### Riverpod Conversion Required
- `ProvisioningScreen` is a plain `StatefulWidget` — must convert to `ConsumerStatefulWidget` to access `ref` for `BleConnector`/`AuthSession`, matching `ControlTab` pattern.

---

## 6. Risks & Constraints

- **HA Heartbeat 21-byte layout uncertainty:** Domain model fields (`HaRole(1) + Epoch(4) + HeartbeatCount(4) + PeerStatus(1) + FailoverTimestamp(4) + FailoverReason(1)`) sum to only 15 bytes — 6 bytes unaccounted. Needs firmware spec (`qos_service.h`) confirmation before implementing `HaHeartbeat.fromBytes()`.
- **ENG_UNLOCK response format unknown:** Domain model says "interpret firmware response (success/failure)" but doesn't specify the mechanism — is it a read-after-write, a notify, or is success implied by no error from `BleGatt.write()`? Needs firmware clarification.
- **ProvisioningScreen Riverpod migration:** Converting from `StatefulWidget` to `ConsumerStatefulWidget` may break existing tests (`test/features/provisioning/provisioning_screen_test.dart`).
- **CI must pass:** `.github/workflows/ci.yml` runs `flutter analyze` + `flutter test` — all new code must pass both.
- **Dependencies:** `flutter_blue_plus: ^1.35.0`, `flutter_riverpod: ^2.6.1`, `mocktail: ^1.0.4`

---

## 7. Recommendations for Plan

### Implementation Order
1. **Infrastructure first:** Add `GattUuids.haHb`, create `HaHeartbeat` codec in `gatt_structs.dart`, add `roleFromString()` to `ManufacturerData`, define CMD reboot opcode constant
2. **Provisioning ROLE write:** Convert `ProvisioningScreen` to `ConsumerStatefulWidget`, wire `_onWriteRole()` to `BleGatt.write()`, add post-write disconnect + navigate back
3. **HA Tab:** Add `haHeartbeatStreamProvider` using `_gattNotifyStream` pattern, convert `HaTab` to `ConsumerWidget`, subscribe + parse + display
4. **Admin Tab ENG_UNLOCK:** Implement PIN dialog, write to `GattUuids.engUnlock`, handle response, call `AuthSession.elevate(AuthRole.engineer)` on success
5. **Admin Tab CMD reboot:** Check engineer auth, show confirmation, write CMD 0x01, handle disconnect
6. **Admin Tab MODE/ROLE write:** Dropdown selector, confirmation dialog, write to respective characteristic

### Reference Pattern
- **Follow `ControlTab._writeCtrl()` pattern** (`control_tab.dart:L84-116`) for all permission-gated GATT writes — it demonstrates auth check → permission guard → confirmation → write → snackbar feedback

### Files that MUST be modified
- `lib/core/gatt/gatt_uuids.dart` — add `haHb` UUID
- `lib/core/gatt/gatt_structs.dart` — add `HaHeartbeat` codec, add CMD opcode constant
- `lib/core/ble/manufacturer_data.dart` — add `roleFromString()` or role name→uint8 map
- `lib/core/providers/metrics_provider.dart` — add `haHeartbeatStreamProvider`
- `lib/features/provisioning/provisioning_screen.dart` — convert to ConsumerStatefulWidget, wire GATT write, add post-reboot handling
- `lib/features/device/ha/ha_tab.dart` — full rewrite: subscribe + parse + display
- `lib/features/device/admin/admin_tab.dart` — implement ENG_UNLOCK, CMD reboot, MODE/ROLE write
- `test/gatt_structs_test.dart` — add `HaHeartbeat` codec tests
- `test/features/provisioning/provisioning_screen_test.dart` — add GATT write integration tests
- New: `test/features/device/ha/ha_tab_test.dart`
- New: `test/features/device/admin/admin_tab_test.dart`

### Files that MUST NOT be modified
- `lib/core/auth/permission_guard.dart` — already has all needed `GattAction` entries
- `lib/core/auth/auth_session.dart` — `elevate()`/`demote()` already work correctly
- `lib/core/ble/ble_gatt.dart` — `write()`/`subscribe()` APIs are sufficient
- `lib/features/device/device_screen.dart` — already routes to `HaTab`/`AdminTab` correctly

---

## 8. Knowledge Graph

### Key Entities
- `GattUuids` (class) — SSOT for all GATT characteristic UUIDs; missing `haHb`
- `BleGatt` (class) — GATT read/write/subscribe infrastructure; sufficient for all features
- `PermissionGuard` (class) — SSOT for GATT action permissions; already has all needed actions
- `AuthSession` (class) — manages engineer elevation; `elevate()`/`demote()` ready
- `ControlTab` (class) — reference pattern for permission-gated GATT writes
- `_gattNotifyStream` (function) — reusable subscribe+parse factory for GATT notifications
- `ManufacturerData` (class) — SSOT for role constants; needs `roleFromString()` addition
- `HaHeartbeat` (class, MISSING) — 21-byte codec needed for HA heartbeat parsing
- `ProvisioningScreen` (class) — needs ConsumerStatefulWidget conversion + GATT write wiring
- `HaTab` (class) — static placeholder, needs full implementation
- `AdminTab` (class) — 5 TODO stubs, needs ENG_UNLOCK/CMD/MODE/ROLE implementation

### Key Relation Chains
- `ProvisioningScreen._onWriteRole` → writes → `GattUuids.role` → via → `BleGatt.write()` → uses → `ManufacturerData.roleGateway` (uint8 value)
- `HaTab` → subscribes → `GattUuids.haHb` → via → `_gattNotifyStream()` → parses → `HaHeartbeat.fromBytes()`
- `AdminTab.engUnlock` → writes → `GattUuids.engUnlock` → on success → `AuthSession.elevate(engineer)` → enables → `AdminTab.cmdReboot`
- `AdminTab.cmdReboot` → checks → `PermissionGuard.canWrite(engineer, cmdReboot)` → writes → `GattUuids.cmd` → triggers → device reboot → `BleConnector.close()`
- `ControlTab._writeCtrl` → validates → `PermissionGuard` → writes → `BleGatt.write()` (reference pattern for all admin writes)

### Uncertainties / Conflicts
- **HA heartbeat byte layout:** Domain model fields sum to 15 bytes but payload is 21 bytes — 6 bytes unaccounted (medium confidence, needs firmware spec)
- **ENG_UNLOCK response mechanism:** Unknown whether success is indicated by write-response, notify, or implicit no-error (all 3 workers flag this)
- **PIN brute-force lockout:** Domain model mentions "remaining attempts" but no firmware confirmation of lockout enforcement (low confidence)
- **AdminTab TODO count:** Code Map Worker reports 5 TODOs (L29-79), Config Worker reports 4 TODOs (L30, L42, L54, L79) — minor line number discrepancy but same set of stubs

### Merged Graph
No `merged_graph.json` was produced by `tools/merge_research_graph.py`. Graph data was manually merged from all 3 worker reports above.
