# Research Brief: Device Identity Migration + BLE Scan Lifecycle + Capability Compat Matrix
**Date:** 2026-03-22
**Task:** Implement device identity migration (App-generated UUIDv4 stable ID replacing MAC as primary key across 9 touch points), BLE scan lifecycle (visible scan + TTL eviction + task-scoped connection + exponential backoff reconnect), and capability-driven compat matrix (negotiation read order + graceful degradation UI).
**Domain Model:** `docs/domain/2026-03-22-implement-device-identity-migration-app--domain-model.md`

---

## 1. Existing Code Map

### 1.1 ScannedDevice (Touch Point #1, #2)
- **Current location:** `lib/core/ble/ble_models.dart:L33-L92`
- **Current behavior:** `ScannedDevice.id` is BLE `remoteId` (MAC string). No StableId concept exists. `copyWith()` does not allow changing `id` or `name` (hardcoded from constructor).
- **Key functions:**
  - `ScannedDevice({required this.id, ...})` — constructor, `id` is final String (MAC)
  - `copyWith({rssi, smoothedRssi, status, lastSeen, mfgData, alias})` — no `id` in copyWith
  - `deviceStatusFromLastSeen(DateTime lastSeen, ...)` — pure function
  - `emaRssi(int newRssi, double? previous, {double alpha})` — pure function
- **Config source:** Thresholds hardcoded: `staleDuration=10s`, `offlineDuration=30s` (L14-16)

### 1.2 BleScanner._devices map (Touch Point #2)
- **Current location:** `lib/core/ble/ble_scanner.dart:L14`
- **Current behavior:** `_devices = <String, ScannedDevice>{}` — keyed by MAC (`r.device.remoteId.str` at L64). New ScannedDevice created with `id: id` where `id` = MAC (L90-91).
- **Key functions:**
  - `start({bool dutyCycle = false})` — clears devices, starts scan
  - `_onScanResults(List<ScanResult>)` — processes results, keys by MAC
  - `_updateDeviceStatuses()` — iterates `_devices.entries`, updates status but does NOT evict offline devices
  - `_startContinuousScan()` — uses `removeIfGone: Duration(seconds: 15)` at FlutterBluePlus level
  - `stop()` / `dispose()`
- **Missing:** No TTL eviction (offline devices stay in `_devices` forever). Only FlutterBluePlus `removeIfGone:15s` removes at platform level, but `_devices` map retains them.

### 1.3 ConnectedDevice (Touch Point #3, #9)
- **Current location:** `lib/core/providers/device_provider.dart:L8-L20`
- **Current behavior:** `ConnectedDevice.id` is MAC. No `mac` field. `ConnectedDeviceNotifier.connect(ScannedDevice)` copies `device.id` (MAC) directly.
- **Key functions:**
  - `ConnectedDevice({required this.id, required this.name, required this.mode, required this.role})`
  - `ConnectedDeviceNotifier.connect(ScannedDevice device)` — creates ConnectedDevice from scan result
  - `ConnectedDeviceNotifier.disconnect()` — sets state to null

### 1.4 BleConnector.connect(deviceId) (Touch Point #4)
- **Current location:** `lib/core/ble/ble_connector.dart:L45-L115`
- **Current behavior:** `connect(String deviceId)` takes MAC, creates `BluetoothDevice.fromId(deviceId)` at L50. FlutterBluePlus requires MAC for `fromId()`.
- **Key functions:**
  - `connect(String deviceId)` — takes MAC, creates device, listens to connection state, performs handshake
  - `_performHandshake()` — writes PEER_ROLE=0x02
  - `disconnect()` — sets `_intentionalDisconnect=true`, cancels reconnect
  - `connectedDeviceId` getter — returns `_device?.remoteId.str` (MAC)
- **Auto-reconnect:** On unexpected disconnect, calls `_reconnect!.startReconnect(deviceId)` with MAC at L93.

### 1.5 BleReconnect.startReconnect(deviceId) (Touch Point #5)
- **Current location:** `lib/core/ble/ble_reconnect.dart:L26-L29`
- **Current behavior:** `startReconnect(String deviceId, ...)` takes MAC, passes to `_connect(deviceId)` which calls `BleConnector.connect(deviceId)`.
- **Key functions:**
  - `startReconnect(String deviceId, {onGiveUp, onSuccess})` — starts backoff loop
  - `_tryReconnect(String deviceId, ...)` — recursive attempt with exponential backoff
  - `cancel()` / `dispose()`

### 1.6 BackoffConfig
- **Current location:** `lib/core/ble/backoff_config.dart:L1-L20`
- **Current behavior:** Value object with `baseDelay=1s`, `maxDelay=32s`, `maxAttempts=5`. Already well-designed.
- **Key functions:** `delayForAttempt(int attempt) -> Duration`

### 1.7 Devices Table PK (Touch Point #6)
- **Current location:** `lib/core/data/tables/devices.dart:L1-L22`
- **Current behavior:** `Devices` table has `TextColumn get id => text()()` as PK. No `mac` column. Schema version = 1 (`lib/core/data/database.dart:L15`).
- **Migration needed:** Add `mac` column, change `id` semantics from MAC to StableId, bump schema version to 2 with migration.

### 1.8 DeviceRepository.upsertDevice(id:) (Touch Point #7)
- **Current location:** `lib/core/data/repositories/device_repository.dart:L20-L46`
- **Current behavior:** `upsertDevice({required String id, ...})` — `id` is MAC. `getDevice(String id)` queries by MAC.
- **Key functions:**
  - `getAllDevices()`, `getDevicesByNetwork(int)`, `getDevice(String id)`, `upsertDevice(...)`, `updateStatus(String id, String status)`

### 1.9 Navigation Route Parameter (Touch Point #8)
- **Current location:** `lib/main.dart:L16-L18`
- **Current behavior:** GoRoute `/device/:id` extracts `state.pathParameters['id']` — currently MAC.
- **Callers:** `scanner_screen.dart:L101` — `context.push('/device/${device.id}')` uses MAC.
- **Also:** `/provisioning/:id` at L21-22 uses same pattern.

### 1.10 CapabilityRegistry + CapabilityNegotiator
- **Current location:** `lib/core/capability/capability_registry.dart:L1-L53`, `lib/core/capability/capability_negotiator.dart:L1-L44`
- **Current behavior:**
  - `CapabilityRegistry._handlers` — static map of 5 capabilities with `tabLabel` and `minVersion`
  - `CapabilityRegistry.fallbackForRole(int roleValue)` — returns default caps by role
  - `CapabilityNegotiator.negotiate(List<Capability>)` — classifies caps into `enabledTabs`, `incompatible`, `unknown`
  - `NegotiationResult` — has `enabledTabs: List<String>`, `incompatible: List<Capability>`, `unknown: List<String>`
- **Missing:** No `DegradationInfo` value object. `NegotiationResult.incompatible` has `List<Capability>` but no `requiredVersion` or `degradedMessage`. No GATT CAPABILITY char read logic — only role-based fallback used.

### 1.11 Capability Characteristic Read
- **Current location:** `lib/core/gatt/gatt_uuids.dart:L28`
- **Current behavior:** `GattUuids.capability = '6f8a9c19-...'` defined but **never read**. DeviceScreen at L78 only uses `CapabilityRegistry.fallbackForRole()` — no GATT read attempted.
- **Gap:** The negotiation read order (GATT first → role fallback) is defined in domain model but not implemented.

### 1.12 BleGatt
- **Current location:** `lib/core/ble/ble_gatt.dart:L1-L66`
- **Current behavior:** Generic GATT read/write/subscribe wrapper using `BleConnector.services`. Not a Riverpod provider — instantiated ad-hoc via `BleGatt(connector)`.

### 1.13 ManufacturerData
- **Current location:** `lib/core/ble/manufacturer_data.dart:L1-L83`
- **Current behavior:** Parses BLE advertising manufacturer data. Role constants: `roleGateway=0x01`, `roleEndDevice=0x02`, `roleCentralController=0x04`, `roleUnprovisioned=0x00`.

### 1.14 DeviceScreen
- **Current location:** `lib/features/device/device_screen.dart:L1-L178`
- **Current behavior:** Takes `deviceId` (MAC) as constructor param. Uses it for `AppBar.title`, tab widgets, and reconnect. Watches `connectedDeviceProvider` for role-based capability negotiation. No degradation badges, no "limited mode" banner.

---

## 2. Caller / Dependency Map

### 2.1 ScannedDevice.id (MAC) propagation

| Source | Uses ScannedDevice.id | How |
|--------|----------------------|-----|
| `ble_scanner.dart:L64,L90` | Sets `id = r.device.remoteId.str` | Creates ScannedDevice with MAC |
| `ble_scanner.dart:L14` | `_devices[id]` map key | MAC as key |
| `scanner_screen.dart:L99` | `connector.connect(device.id)` | Passes MAC to BleConnector |
| `scanner_screen.dart:L101` | `context.push('/device/${device.id}')` | MAC in URL |
| `scanner_screen.dart:L95` | `connectedDeviceProvider.notifier.connect(device)` | ScannedDevice with MAC id |
| `device_provider.dart:L32` | `ConnectedDevice(id: device.id, ...)` | Copies MAC from ScannedDevice |
| `scan_device_tile.dart:L17` | `device.displayName`, `device.id` search | Display/search |

### 2.2 ConnectedDevice.id (MAC) propagation

| Source | Uses ConnectedDevice.id | How |
|--------|------------------------|-----|
| `device_screen.dart:L77` | `ref.watch(connectedDeviceProvider)` | Role for capability negotiation |
| `metrics_provider.dart:L30,L63,L125` | `ref.watch(connectedDeviceProvider)` | Null-check only, not using id |
| `settings_screen.dart:L17` | `ref.watch(connectedDeviceProvider)` | Display name and mode |
| `settings_screen.dart:L77` | `connectedDeviceProvider.notifier.disconnect()` | Reset state |

### 2.3 BleConnector.connect(deviceId) callers

| Source | Calls | Via |
|--------|-------|-----|
| `scanner_screen.dart:L99` | `connector.connect(device.id)` | Direct — MAC |
| `ble_reconnect.dart:L44` | `_connect(deviceId)` | Callback from `bleReconnectProvider` |
| `device_screen.dart:L67` | `connector.connect(deviceId)` | Retry on error — `deviceId` from route param (MAC) |
| `ble_connector.dart:L172-L173` | `connect: (deviceId) => connector.connect(deviceId)` | BleReconnect factory |

### 2.4 DeviceScreen.deviceId (route param) propagation

| Source | Uses deviceId | How |
|--------|--------------|-----|
| `main.dart:L17-L18` | `state.pathParameters['id']` | GoRouter extracts from URL |
| `device_screen.dart:L35` | `AppBar(title: Text(deviceId))` | Display |
| `device_screen.dart:L67` | `connector.connect(deviceId)` | Reconnect on error |
| `device_screen.dart:L94-L95,L100-L101` | `ControlTab(deviceId:)`, `AdminTab(deviceId:)` | Pass to child tabs |
| `device_screen.dart:L144-L148` | `DashboardTab(deviceId:)`, `HaTab(deviceId:)`, `_PlaceholderTab(deviceId:)` | Pass to child tabs |
| `provisioning_screen.dart:L59-L66` | `widget.deviceId` display | Shows in card |
| `provisioning_screen.dart:L199` | `device ${widget.deviceId}` | Confirmation dialog |

### 2.5 Database/Repository callers

| Source | Calls | Via |
|--------|-------|-----|
| No callers found | `DeviceRepository.upsertDevice` | **Not actively called** — repository exists but no code calls it yet |

### 2.6 shared_preferences usage
- **Not used anywhere in Dart code** — dependency declared in pubspec.yaml but no imports found. Available for IdentityRepository persistence.

---

## 3. Config & SSOT Analysis

| Value | SSOT Location | Current Value | Duplicates/Hardcodes |
|-------|--------------|---------------|---------------------|
| staleThreshold | `ble_scanner.dart:L28` | 10s | Also in `ble_models.dart:L15` as default param `staleDuration` |
| offlineThreshold | `ble_scanner.dart:L29` | 30s | Also in `ble_models.dart:L16` as default param `offlineDuration` |
| removeIfGone | `ble_scanner.dart:L126` | 15s | FlutterBluePlus platform level — different from app offlineThreshold (30s) |
| emaAlpha | `ble_scanner.dart:L21` | 0.3 | Also default in `ble_models.dart:L27` |
| scanWindow | `ble_scanner.dart:L24` | 2s | Hardcoded |
| pauseWindow | `ble_scanner.dart:L25` | 3s | Hardcoded |
| backoff.baseDelay | `backoff_config.dart:L9` | 1s | Single location |
| backoff.maxDelay | `backoff_config.dart:L10` | 32s | Single location |
| backoff.maxAttempts | `backoff_config.dart:L11` | 5 | Single location |
| connect.timeout | `ble_connector.dart:L105` | 10s | Hardcoded |
| QoS service UUID | `gatt_uuids.dart:L8` | `00001820-...` | Also in `ble_scanner.dart:L32-L35` (reads from GattUuids — OK) |
| capability char UUID | `gatt_uuids.dart:L28` | `6f8a9c19-...` | Single location, but never read |
| Capability handlers | `capability_registry.dart:L16-L22` | 5 handlers | Single location |
| DB schemaVersion | `database.dart:L15` | 1 | Single location |
| uuid package | `pubspec.yaml` | **NOT present** | Must add `uuid` package for UUIDv4 generation |

---

## 4. External References

| Topic | Industry Standard | Our Implementation | Gap |
|-------|------------------|-------------------|-----|
| Device identity stability | BLE apps generate app-layer UUID (e.g., HomeKit, Matter use unique IDs) because MAC randomization on iOS/Android makes remoteId unreliable | Using `remoteId` (MAC) directly as primary key | **Critical gap** — iOS uses random identifiers, MAC can change on reset. App-generated UUID needed. |
| TTL eviction | Standard pattern: maintain in-memory list with periodic sweep removing devices past threshold | `_updateDeviceStatuses()` marks stale/offline but never removes entries from `_devices` map | **Gap** — no eviction. Offline devices accumulate indefinitely. |
| Task-scoped scan | Common mobile BLE pattern: stop scan before connect (saves battery, reduces interference) | `_stopScan()` called in `_onDeviceTap()` before `connect()` | **Implemented** — scan stops on connect. Missing: auto-resume on return to scanner. |
| Exponential backoff reconnect | Industry standard: base * 2^attempt, capped at max, with max attempts | `BackoffConfig` + `BleReconnect` fully implements this pattern | **Implemented** |
| GATT capability negotiation | BLE profiles often read a "features" characteristic to determine supported features (e.g., Heart Rate Profile Feature char) | Only role-based fallback used; CAPABILITY char defined but never read | **Gap** — GATT read step missing from negotiation flow |
| Graceful degradation UI | Material Design: use badges/chips for warnings, show degraded features rather than hiding | No degradation UI — incompatible caps silently excluded from tab list | **Gap** — no warning badges, no "limited mode" banner |
| Drift DB migration | Drift supports `onUpgrade` with `MigrationStrategy` and schema versioning | Schema version 1, no migration infrastructure | **Must add** — version bump to 2 with `mac` column addition |
| shared_preferences for identity mapping | Lightweight key-value store suitable for small lookup tables (<1000 entries) | Dependency declared but not used | **Available** — suitable for MAC-to-StableId mapping (alternative: Drift table) |

---

## 5. Risks & Constraints

- **iOS remoteId is NOT a MAC address** — it's a system-generated UUID that can change. The identity migration is even more critical on iOS than Android. The `BluetoothDevice.fromId()` call in `BleConnector.connect()` requires the platform identifier, NOT StableId. The resolution layer must map StableId to platform remoteId.
- **Database schema migration** — existing `Devices` table rows use MAC as PK. Migration must handle existing data (map old MAC PKs to new StableId PKs, add `mac` column). Drift's `onUpgrade` callback needed.
- **`uuid` package missing** — pubspec.yaml does not include the `uuid` package. Must be added for UUIDv4 generation.
- **shared_preferences is declared but unused** — can be leveraged for IdentityRepository, or a new Drift table could be used instead. Decision needed.
- **`removeIfGone: 15s` vs `offlineThreshold: 30s` mismatch** — FlutterBluePlus removes devices from platform scan results after 15s, but app considers devices offline at 30s. The platform removal means `_onScanResults` won't receive updates after 15s, but `_devices` map retains stale entries. This needs alignment.
- **No test coverage for identity layer** — DeviceIdentity, IdentityRepository don't exist yet. All 9 touch points need coordinated migration.
- **ConnectedDevice has no `mac` field** — adding it requires updating `ConnectedDeviceNotifier.connect()` and all downstream consumers.
- **DeviceScreen displays `deviceId` as AppBar title** — after migration, this will show a UUID instead of a friendly name. Should use `connectedDeviceProvider?.name` instead.
- **BleReconnect wiring** — `bleReconnectProvider` creates reconnect with `connect: (deviceId) => connector.connect(deviceId)`. After migration, the reconnect must resolve StableId to MAC before calling FlutterBluePlus. The resolution can happen inside `BleConnector.connect()` itself.
- **Backward compatibility** — existing stored devices in `Devices` table have MAC as PK. A DB migration strategy must either: (a) delete existing data, or (b) create StableIds for existing rows and move MAC to new column.
- **Async identity resolution in sync scan callback** — `_onScanResults` is synchronous. Identity resolution from Drift DB is async. Need in-memory cache populated at startup, updated lazily.

---

## 6. Recommendations for Plan

### Architecture Decisions
1. **IdentityRepository: use Drift table, not SharedPreferences** — Drift is already the DB layer, and a `DeviceIdentities` table (`stableId TEXT PK, mac TEXT UNIQUE, createdAt INTEGER`) keeps all persistent data in one DB with transactional consistency.
2. **Resolution layer inside BleConnector** — `BleConnector.connect(String stableId)` should resolve StableId to MAC via `IdentityRepository` before calling `BluetoothDevice.fromId(mac)`. This keeps the migration transparent to UI callers.
3. **Add `uuid` package** to pubspec.yaml for UUIDv4 generation.
4. **BleScanner owns identity resolution at scan time** — when `_onScanResults` receives a MAC, it queries `DeviceIdentityService` to get/create StableId, then uses StableId as `_devices` map key and `ScannedDevice.id`.
5. **Add `mac` field to ScannedDevice and ConnectedDevice** — both need MAC for BLE operations while using StableId as primary identity.
6. **In-memory cache in DeviceIdentityService** — load all mappings at startup, sync writes. Avoids async in scan callback.

### Implementation Order
1. **Create identity layer first** (DeviceIdentity model, IdentityRepository, DeviceIdentityService) — foundation for all other changes
2. **Migrate BleScanner** — scan results resolve MAC to StableId
3. **Migrate ConnectedDevice** — add `mac` field
4. **Migrate BleConnector** — accept StableId, resolve to MAC
5. **Migrate BleReconnect** — transparent via BleConnector
6. **Migrate database** — add mac column, bump schema, add migration
7. **Migrate navigation** — StableId in route params
8. **Add TTL eviction** — remove offline devices from `_devices` map
9. **Add GATT capability read** — read CAPABILITY char before fallback
10. **Add DegradationInfo + UI** — warning badges, "limited mode" banner

### Files That MUST Be Modified
- `lib/core/ble/ble_models.dart` — add `mac` field to `ScannedDevice`
- `lib/core/ble/ble_scanner.dart` — identity resolution, TTL eviction
- `lib/core/ble/ble_connector.dart` — StableId to MAC resolution
- `lib/core/ble/ble_reconnect.dart` — may need MAC passthrough
- `lib/core/providers/device_provider.dart` — add `mac` to `ConnectedDevice`
- `lib/core/data/tables/devices.dart` — add `mac` column
- `lib/core/data/database.dart` — bump schema, add migration
- `lib/core/data/repositories/device_repository.dart` — accept StableId
- `lib/core/capability/capability_negotiator.dart` — add DegradationInfo
- `lib/core/capability/capability_model.dart` — add DegradationInfo VO
- `lib/features/device/device_screen.dart` — GATT cap read, degradation UI, fix title
- `lib/features/scanner/scanner_screen.dart` — use StableId for navigation
- `lib/main.dart` — route param semantics (no code change needed, just param meaning changes)
- `pubspec.yaml` — add `uuid` package

### Files That MUST BE Created
- `lib/core/identity/device_identity.dart` — DeviceIdentity aggregate, StableId VO
- `lib/core/identity/identity_repository.dart` — Drift-backed MAC to StableId persistence
- `lib/core/identity/device_identity_service.dart` — resolve/assign StableId
- `lib/core/data/tables/device_identities.dart` — Drift table definition
- `lib/core/capability/degradation_info.dart` — DegradationInfo value object
- Tests for all new classes

### Files That MUST NOT Be Modified
- `lib/core/ble/backoff_config.dart` — already well-designed, no changes needed
- `lib/core/ble/ble_service_utils.dart` — generic utility, unchanged
- `lib/core/gatt/gatt_uuids.dart` — CAPABILITY UUID already defined
- `lib/core/gatt/gatt_peer_role.dart` — handshake constants unchanged
- `lib/core/theme/` — no theme changes

### Open Questions for Planner
1. **Should IdentityRepository use Drift or SharedPreferences?** Recommendation: Drift (new table), but confirm.
2. **Database migration strategy for existing Devices rows?** Recommend: generate StableId for existing MAC PKs, copy MAC to new column. Or simply clear data (acceptable for dev stage?).
3. **Should BleScanner.DeviceIdentityService resolution be async?** Reading from Drift is async — `_onScanResults` is currently sync. May need to buffer scan results or use a synchronous in-memory cache populated at startup.
4. **`removeIfGone: 15s` alignment** — should this match `offlineThreshold: 30s`, or should app-level eviction replace FlutterBluePlus's `removeIfGone`?
