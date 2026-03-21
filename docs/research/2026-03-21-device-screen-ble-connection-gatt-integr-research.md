# Research Brief: Device Screen BLE Connection + GATT Integration
**Date:** 2026-03-21
**Task:** Device Screen BLE connection + GATT integration: (1) Call connector.connect() from scanner _onDeviceTap before navigation, await handshake + service discovery, (2) Add connection state indicator in DeviceScreen AppBar (connecting/connected/error with retry), (3) Handle connection failures gracefully with error screen and retry button, (4) Fix BLE notification subscription leak — call cancelWhenDisconnected() before setNotifyValue in ble_gatt.dart subscribe(), (5) Add disconnection detection with auto-reconnect using exponential backoff
**Domain Model:** docs/domain/2026-03-21-device-screen-ble-connection-gatt-integr-domain-model.md

---

## 1. Existing Code Map

### BleConnector (BLE Connection Lifecycle)
- **Current location:** `lib/core/ble/ble_connector.dart:L11`
- **Current behavior:** Manages BLE connect + handshake lifecycle, emits `BleConnectionState` stream. `connect(String deviceId)` (L30) initiates connection + discovers services + performs handshake (`_performHandshake()` at L59 writes PeerRole.phone 0x02). **BUG:** `connect()` future resolves after `_device!.connect()` but before handshake completes — handshake runs asynchronously in a listener, so callers cannot await end-to-end completion.
- **Key functions:** `connect(String deviceId) -> Future<void>`, `_performHandshake() -> Future<void>`, `disconnect() -> Future<void>`
- **Config source:** Connect timeout hardcoded at `ble_connector.dart:L52` as `Duration(seconds: 10)`
- **Provider:** `bleConnectorProvider` at `ble_connector.dart:L103` — Riverpod singleton, no config injection

### BleGatt (GATT Subscription Management)
- **Current location:** `lib/core/ble/ble_gatt.dart:L10`
- **Current behavior:** Thin GATT read/write/subscribe wrapper. `subscribe(String charUuid)` (L50) calls `setNotifyValue(true)` **without** `cancelWhenDisconnected()` — **confirmed notification leak bug**. `setNotifyValue` is also not awaited (fire-and-forget), creating a race condition.
- **Key functions:** `subscribe(String charUuid) -> Stream<Uint8List>`, `write(String charUuid, List<int> data) -> Future<void>`, `read(String charUuid) -> Future<List<int>>`
- **Config source:** Uses UUID constants from `lib/core/gatt/gatt_uuids.dart:L3`

### BleReconnect (Auto-Reconnect)
- **Current location:** `lib/core/ble/ble_reconnect.dart:L6`
- **Current behavior:** Reconnect handler using **fixed 3s delay** (NOT exponential backoff). `maxAttempts=5` (L12, static const). State check uses string comparison `.name == 'disconnected'` instead of enum. **No Riverpod provider** — constructed manually with no lifecycle management.
- **Key functions:** `_tryReconnect(String deviceId) -> Future<void>`
- **Config source:** `maxAttempts` hardcoded at L12, `retryDelay` hardcoded at L13 — domain model requires `BackoffConfig(baseDelay: 1s, maxDelay: 32s, maxAttempts: 5)` value object

### ScannerScreen._onDeviceTap (Connection Orchestration)
- **Current location:** `lib/features/scanner/scanner_screen.dart:L80`
- **Current behavior:** Sets `connectedDeviceProvider` state and navigates via `context.go('/device/${device.id}')` — **does NOT call `BleConnector.connect()`** — no BLE connection is established before navigation.
- **Key functions:** `_onDeviceTap(ScannedDevice device) -> void`

### DeviceScreen (Connection State UI)
- **Current location:** `lib/features/device/device_screen.dart:L12`
- **Current behavior:** Plain `StatelessWidget` with **no** connection state awareness — no AppBar indicator, no error handling, no retry capability.
- **Key functions:** `build(BuildContext context) -> Widget`

### ConnectionBanner (Unused Widget)
- **Current location:** `lib/widgets/connection_banner.dart:L6`
- **Current behavior:** Renders `BleConnectionState` as a banner (L1-33) but is **unused** anywhere in the app. Could be adapted for AppBar indicator or replaced by new `ConnectionStateIndicator` widget.

### BleConnectionState (State Enum)
- **Current location:** `lib/core/ble/ble_models.dart:L95-100`
- **Current behavior:** 4-value enum: `{disconnected, connecting, handshaking, connected}`. **Missing `error` state** required by domain model for error indicator in AppBar.
- **Config source:** SSOT — no duplicates found

---

## 2. Caller / Dependency Map

| Source | Calls | Via |
|--------|-------|-----|
| `scanner_screen.dart:L80` `_onDeviceTap` | `connectedDeviceProvider.notifier.connect()` | Riverpod ref.read |
| `scanner_screen.dart:L84` `_onDeviceTap` | `context.go('/device/${device.id}')` | GoRouter |
| `settings_screen.dart:L76` disconnect | `bleConnectorProvider.disconnect()` | Riverpod ref.read |
| `settings_screen.dart:L77` disconnect | `connectedDeviceProvider.notifier.disconnect()` | Riverpod ref.read |
| `metrics_provider.dart:L17` `statusStreamProvider` | `BleGatt(connector).subscribe(GattUuids.status)` | direct instantiation |
| `metrics_provider.dart:L30` `evtStreamProvider` | `BleGatt(connector).subscribe(GattUuids.evt)` | direct instantiation |
| `metrics_provider.dart:L43` `metricsStreamProvider` | `BleGatt(connector).subscribe(GattUuids.metricsV2)` | direct instantiation |
| `control_tab.dart:L108` `_writeCtrl` | `BleGatt(connector).write(GattUuids.ctrl, ...)` | direct instantiation |
| `ble_gatt.dart:L11` `BleGatt` | `BleConnector._connector.services` | constructor dependency |
| `ble_connector.dart:L35` `connect` | `_device!.connectionState.listen()` | FlutterBluePlus stream |
| `ble_reconnect.dart:L30` `_tryReconnect` | `_connector.connect(deviceId)` | direct call |

---

## 3. Config & SSOT Analysis

| Value | SSOT Location | Current Value | Duplicates/Hardcodes |
|-------|--------------|---------------|---------------------|
| maxAttempts | `ble_reconnect.dart:L12` | `5` (static const) | None — but NOT configurable (domain model says should be) |
| retryDelay | `ble_reconnect.dart:L13` | `3s` (fixed) | **MISMATCH** — domain model requires exponential 1s→32s cap |
| connect timeout | `ble_connector.dart:L52` | `10s` | Hardcoded in `_device!.connect(timeout:)` |
| BleConnectionState | `ble_models.dart:L95-100` | 4-value enum | Consistent usage in `ble_connector.dart`, `connection_banner.dart` |
| PeerRole.phone | `gatt_peer_role.dart` | `0x02` | Used in `ble_connector.dart:L64` handshake |
| EMA alpha | `ble_models.dart:L27` | `0.3` | Hardcoded default param |
| staleDuration | `ble_models.dart:L15` | `10s` | Hardcoded default param |
| offlineDuration | `ble_models.dart:L16` | `30s` | Hardcoded default param |

**Note:** No external config files (YAML/JSON/env) exist for BLE parameters — all config is hardcoded in Dart source.

---

## 4. External References

| Topic | Industry Standard | Our Implementation | Gap |
|-------|------------------|-------------------|-----|
| cancelWhenDisconnected | flutter_blue_plus: `cancelWhenDisconnected(sub)` BEFORE `setNotifyValue(true)` — "make sure you have this line!" | Missing entirely in `subscribe()` | **YES — leak bug** |
| subscribe() return type | Should return `StreamSubscription` (for cancelWhenDisconnected handle) | Returns `Stream<Uint8List>` (no subscription handle) | **YES — API incompatible** |
| setNotifyValue await | Must `await` to ensure descriptor write completes | Not awaited (fire-and-forget) | **YES — race condition** |
| Backoff strategy | Exponential (1→2→4→8→16→32s) with jitter (AWS/Google/Polly) | Fixed 3s delay | **YES — missing** |
| Jitter | Full or equal jitter recommended for battery efficiency | None | **YES — missing** |
| Error state enum | Connecting/connected/disconnected/error (standard FSM) | No `error` state in enum | **YES — missing** |
| Handshake failure handling | Disconnect + surface error (per domain model) | Catches error, transitions to `connected` silently | **YES — silent failure** |
| connect() completion | Caller should know when handshake done before navigating | Future resolves at `device.connect()`, not after handshake | **YES — premature resolution** |
| Riverpod BLE pattern | StreamProvider for connection state, autoDispose for cleanup | No connection state StreamProvider; no autoDispose | **YES — missing** |
| Android BLE best practice | Queue GATT ops; close GATT → wait → reconnect | No GATT op queue | Partial |

**Key Sources:**
- [flutter_blue_plus pub.dev](https://pub.dev/packages/flutter_blue_plus) — cancelWhenDisconnected, setNotifyValue patterns
- [AWS backoffAlgorithm](https://github.com/FreeRTOS/backoffAlgorithm) — exponential backoff with jitter
- [Punch Through BLE guide](https://punchthrough.com/manage-ble-connection/) — connection supervision
- [Medium: BLE+Riverpod](https://medium.com/@alaxhenry0121/building-bluetooth-connected-flutter-apps-with-riverpod-the-guide-i-wish-i-had-b423110847ab) — StreamProvider patterns

---

## 5. Cross-cutting Concerns

### Config ↔ Code Mismatches
- **retryDelay**: Config Worker found `ble_reconnect.dart:L13` hardcodes 3s; Code Map Worker confirmed fixed delay; External Worker confirmed industry standard is exponential 1→32s with jitter. **Triple confirmation — highest priority fix.**
- **BleConnectionState enum**: Code Map Worker found 4-value enum in `ble_models.dart:L95`; External Worker found industry standard requires `error` state; Domain Model also requires error state for UI indicator. **Missing state blocks UI work.**

### Unused Code ↔ New Requirements
- **ConnectionBanner** (`lib/widgets/connection_banner.dart:L6`): Code Map Worker found it exists but is unused. Domain Model requires a new `ConnectionStateIndicator` widget. Decision needed: reuse/adapt ConnectionBanner or replace entirely.

### Test Gaps
- **NO tests** for: `BleConnector`, `BleGatt`, `BleReconnect`, `ScannerScreen._onDeviceTap`, `ConnectionBanner` (Code Map Worker)
- All three metric stream providers (`statusStreamProvider`, `evtStreamProvider`, `metricsStreamProvider`) consume `BleGatt.subscribe()` — the leak fix affects all three but none have tests.

### API Design Conflict
- **subscribe() return type**: External Worker notes flutter_blue_plus requires `StreamSubscription` handle for `cancelWhenDisconnected()`, but current API returns `Stream<Uint8List>`. This means the leak fix requires either: (a) changing the public API to return `StreamSubscription`, or (b) registering the cancel guard internally within `subscribe()`. Open design decision.

### Silent Failure
- External Worker found `BleConnector` catches handshake errors and transitions to `connected` anyway — contradicts domain model which says "HandshakeFailed → disconnect and surface error". Code Map Worker confirmed the listener-based pattern but did not flag silent failure explicitly.

### No Contradictions Between Workers
- All three workers agree on: missing `cancelWhenDisconnected()`, fixed 3s delay, `_onDeviceTap` not calling `connect()`, `DeviceScreen` lacking connection awareness.

---

## 6. Risks & Constraints

- **Notification leak is a production bug** — not just a missing feature. Each disconnect/reconnect cycle leaks subscription resources. Priority: fix BEFORE adding new features.
- **`subscribe()` API change** may break `statusStreamProvider`, `evtStreamProvider`, `metricsStreamProvider` if return type changes from `Stream` to `StreamSubscription`. Must coordinate or keep internal.
- **`connect()` awaitable refactor** requires a `Completer` or state-stream await pattern — changes the async contract for all callers including `BleReconnect._tryReconnect()`.
- **BleConnectionState enum change** (adding `error`) impacts all consumers: `BleConnector`, `ConnectionBanner`, `BleReconnect` (string comparison), any switch statements.
- **`BleReconnect` string comparison** (`state.name == 'disconnected'`) will break silently if enum values change — must switch to enum comparison during refactor.
- **No external config** — all BLE params are hardcoded. While domain model suggests `BackoffConfig` value object, for this task keeping config as constructor params (not external files) is acceptable.
- **`flutter_blue_plus: ^1.35.0`** (pubspec.yaml:L33) — `cancelWhenDisconnected()` API is available in this version. No dependency upgrade needed.
- **`mocktail: ^1.0.4`** (pubspec.yaml:L48) — available for mocking `BleConnector` in new tests.
- **CI** (`.github/workflows/ci.yml`) runs `flutter test` with no path filter — all new tests will be picked up automatically.

---

## 7. Recommendations for Plan

### Implementation Order
1. **Fix `BleConnectionState` enum** — add `error` state to `ble_models.dart` (prerequisite for all UI work)
2. **Fix notification leak** — add `cancelWhenDisconnected()` in `ble_gatt.dart:subscribe()` (isolated bug fix, low blast radius if cancel guard is internal)
3. **Make `connect()` awaitable** — refactor `ble_connector.dart` so `connect()` completes only after handshake (or emits error state on failure)
4. **Wire up `_onDeviceTap`** — call `bleConnectorProvider.connect()` before navigation in `scanner_screen.dart`
5. **Add connection state UI** — `ConnectionStateIndicator` in DeviceScreen AppBar + `ConnectionErrorScreen`
6. **Rewrite `BleReconnect`** — exponential backoff (base 1s, cap 32s), enum comparison, expose as Riverpod provider

### Files that MUST be modified
- `lib/core/ble/ble_models.dart` — add `error` to `BleConnectionState` enum
- `lib/core/ble/ble_gatt.dart` — add `cancelWhenDisconnected()` before `setNotifyValue(true)`; await `setNotifyValue`
- `lib/core/ble/ble_connector.dart` — make `connect()` awaitable through handshake; add error state transitions
- `lib/core/ble/ble_reconnect.dart` — rewrite with exponential backoff, enum comparison, Riverpod provider
- `lib/features/scanner/scanner_screen.dart` — `_onDeviceTap` must call `bleConnectorProvider.connect()` before navigation
- `lib/features/device/device_screen.dart` — add connection state indicator + error/retry handling

### Files that MUST NOT be modified
- `lib/core/gatt/gatt_uuids.dart` — UUID constants are stable
- `lib/core/gatt/gatt_peer_role.dart` — PeerRole values are stable
- `lib/core/domain/connection_mode.dart` — ConnectionMode enum is stable
- `pubspec.yaml` — no dependency changes needed (`cancelWhenDisconnected()` already available)

### Design Decisions Needed
1. **`subscribe()` API**: Return `StreamSubscription` (breaking change) vs register cancel guard internally (transparent fix)?
2. **`ConnectionBanner` reuse**: Adapt existing widget or create new `ConnectionStateIndicator`?
3. **`BackoffConfig` injection**: Constructor param on `BleReconnect` or remain as named constants?
4. **Handshake failure policy**: Disconnect + error (domain model) or fall back to permissive mode (current behavior)?

---

## 8. Knowledge Graph

### Key Entities
- `BleConnector` (class) — BLE connect + handshake lifecycle manager at `ble_connector.dart:L11`
- `BleGatt` (class) — GATT read/write/subscribe wrapper at `ble_gatt.dart:L10`
- `BleReconnect` (class) — auto-reconnect handler at `ble_reconnect.dart:L6`
- `BleConnectionState` (enum) — 4-state connection lifecycle at `ble_models.dart:L95`
- `DeviceScreen` (class) — StatelessWidget, no connection awareness at `device_screen.dart:L12`
- `ConnectionBanner` (class) — unused connection state widget at `connection_banner.dart:L6`
- `_onDeviceTap` (function) — scanner tap handler, no BLE connect at `scanner_screen.dart:L80`
- `statusStreamProvider` / `evtStreamProvider` / `metricsStreamProvider` (providers) — all consume `BleGatt.subscribe()`, all affected by leak fix
- `cancelWhenDisconnected` (external_fact) — flutter_blue_plus required pattern before `setNotifyValue`
- `exponential_backoff_jitter` (external_fact) — industry standard for reconnect (base 1s, cap 32s, jitter)

### Key Relation Chains
- `_onDeviceTap` → sets → `ConnectedDeviceNotifier` → navigates → `DeviceScreen` (⚠️ missing: `BleConnector.connect()` call)
- `BleGatt.subscribe()` → calls → `setNotifyValue(true)` → leaks → notification (⚠️ missing: `cancelWhenDisconnected()` guard)
- `BleReconnect._tryReconnect` → calls → `BleConnector.connect()` → uses → fixed 3s delay (⚠️ should be: exponential backoff)
- `statusStreamProvider` / `evtStreamProvider` / `metricsStreamProvider` → all depend on → `BleGatt.subscribe()` → all affected by leak fix
- `BleConnector.connect()` → listener → `discoverServices()` → `_performHandshake()` → emits `connected` (⚠️ future resolves before handshake)

### Uncertainties / Conflicts
- **subscribe() API design**: Whether to change return type (`Stream` → `StreamSubscription`) or keep internal — both valid, trade-off between API clarity and backward compatibility (External Worker: medium confidence)
- **Handshake failure policy**: Domain model says "disconnect and surface error" but current code is intentionally permissive — needs product decision (External Worker: medium confidence)
- **Jitter necessity**: Full jitter recommended for server fleets; less critical for single-device mobile app but still good practice for battery (External Worker: medium confidence)
- **`BleConnectionState.error` state**: External Worker flagged as medium confidence (FSM design convention); domain model confirms it's needed for UI — upgrading to high confidence based on cross-reference

### Merged Graph
No `merged_graph.json` was produced by `tools/merge_research_graph.py`. Graph entities and relations were manually merged from all 3 worker reports with deduplication applied (Code Map Worker entities used as canonical IDs; Config Worker and External Worker entities normalized to match).
