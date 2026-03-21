# Research Brief: Wire Up Fleet Overview App — Enable Scan→Device Navigation + Live Data
**Date:** 2026-03-21
**Task:** Wire up Fleet Overview app: 1) Enable scanner→device navigation (uncomment context.go in scanner_screen.dart), 2) Subscribe dashboard_tab to live STATUS/METRICS GATT notify streams replacing hardcoded '--' values, 3) Implement CTRL write onTap in control_tab.dart using ble_gatt.write(), 4) Add Semantics widgets to ScanDeviceTile and key interactive elements for accessibility/automation testing.
**Domain Model:** docs/domain/2026-03-21-wire-up-fleet-overview-app-1-enable-scan-domain-model.md

---

## 1. Existing Code Map

### Scanner→Device Navigation
- **Current location:** `lib/features/scanner/scanner_screen.dart:L78-81`
- **Current behavior:** `_onDeviceTap()` has `context.go('/device/${device.id}')` **commented out**; `go_router` is NOT imported in this file
- **Key functions:** `_onDeviceTap(ScannedDevice device)` — called from `ScanDeviceTile(onTap:)` at L200-203
- **Route definition:** `lib/main.dart:L16` — `/device/:id` → `DeviceScreen(deviceId:)` already exists and matches

### DashboardTab (Live STATUS/METRICS)
- **Current location:** `lib/features/device/dashboard/dashboard_tab.dart:L7`
- **Current behavior:** `StatelessWidget` with 6 `_MetricCard` widgets all showing hardcoded `'--'` placeholder values (L30-37). Does NOT consume any Riverpod provider.
- **Key functions:** `_MetricCard(label, value, unit, icon)` at L46
- **Stream providers (ready but unused):**
  - `statusStreamProvider` at `lib/core/providers/metrics_provider.dart:L12` — subscribes to `GattUuids.status`, filters by `QosStatus.size=13`, maps via `QosStatus.fromBytes()`
  - `metricsStreamProvider` at `lib/core/providers/metrics_provider.dart:L38` — subscribes to `GattUuids.metricsV2`, filters by `QosMetricsV2.size=20`, maps via `QosMetricsV2.fromBytes()`
- **Config source:** `GattUuids.status` at `gatt_uuids.dart:L11`, `GattUuids.metricsV2` at `gatt_uuids.dart:L17`

### ControlTab (CTRL Write)
- **Current location:** `lib/features/device/control/control_tab.dart:L6`
- **Current behavior:** `StatelessWidget` with `onTap` stub: `// TODO: CTRL write with permission check` at L41-42. Does NOT consume any provider or BleGatt.
- **Key functions needed:**
  - `BleGatt.write(charUuid, value)` at `lib/core/ble/ble_gatt.dart:L36-39` — write with response (confirmed write)
  - `PermissionGuard.canWrite(role, action)` at `lib/core/auth/permission_guard.dart:L22-33` — static method
  - `QosCtrl.toBytes()` — **DOES NOT EXIST** (only `QosCtrl.fromBytes()` at `gatt_structs.dart:L95`)
- **Config source:** `GattUuids.ctrl` at `gatt_uuids.dart:L15`

### QosCtrl Serialization (Missing)
- **Current location:** `lib/core/gatt/gatt_structs.dart:L72-111`
- **Current behavior:** `QosCtrl` has `fromBytes()` for deserialization but **no `toBytes()`** for serialization. `QosGwCfgV2.toBytes()` at L153 exists as a reference pattern.
- **QosCtrl fields:** opcode, zone, profile, phy, txPower, interval, latency, jitter
- **QosCtrl.size:** 9 bytes (L93)

### Semantics / Accessibility
- **Current location:** All of `lib/`
- **Current behavior:** **Zero** `Semantics` widgets anywhere in the codebase. All interactive widgets lack accessibility annotations.
- **Key targets:** `ScanDeviceTile` (L8 of scan_device_tile.dart), `_MetricCard` (L46 of dashboard_tab.dart), `FleetSummary` (L8 of fleet_summary.dart)

### authSessionProvider Location
- **Current location:** `lib/features/settings/settings_screen.dart:L10`
- **Current behavior:** Defined inside a feature screen file, not a shared provider. ControlTab needs it for permission checks — importing from settings feature violates clean architecture.

---

## 2. Caller / Dependency Map

| Source | Calls | Via |
|--------|-------|-----|
| `scanner_screen.dart:L60` | `bleScannerProvider` | `ref.read` |
| `scanner_screen.dart:L200-203` | `ScanDeviceTile(onTap: _onDeviceTap)` | direct construction |
| `scanner_screen.dart:L80` | `context.go('/device/...')` | **commented out** |
| `metrics_provider.dart:L13` | `connectedDeviceProvider` | `ref.watch` |
| `metrics_provider.dart:L16-17` | `bleConnectorProvider` → `BleGatt(connector)` | `ref.watch` + constructor |
| `metrics_provider.dart:L19` | `gatt.subscribe(GattUuids.status)` | method call |
| `metrics_provider.dart:L45` | `gatt.subscribe(GattUuids.metricsV2)` | method call |
| `device_screen.dart:L93` | `DashboardTab(deviceId:)` | direct construction |
| `device_screen.dart:L43` | `ControlTab(deviceId:)` | direct construction |
| `settings_screen.dart:L18` | `authSessionProvider` | `ref.watch` |
| `dashboard_tab.dart` | **nobody** — does NOT consume any provider | — |
| `control_tab.dart` | **nobody** — does NOT consume any provider or BleGatt | — |

---

## 3. Config & SSOT Analysis

| Value | SSOT Location | Current Value | Duplicates/Hardcodes |
|-------|--------------|---------------|---------------------|
| GATT Service UUID | `gatt_uuids.dart:L7` | `00001820-...` | `ble_scanner.dart` (reads constant, OK) |
| STATUS char UUID | `gatt_uuids.dart:L11` | `00002a1d-...` | `metrics_provider.dart:L19` (reads constant, OK) |
| METRICS char UUID | `gatt_uuids.dart:L17` | `00002a23-...` | `metrics_provider.dart:L45` (reads constant, OK) |
| CTRL char UUID | `gatt_uuids.dart:L15` | `00002a21-...` | Not yet used in control_tab (to be wired) |
| QosStatus.size | `gatt_structs.dart:L33` | 13 | `metrics_provider.dart:L20` (reads constant, OK) |
| QosCtrl.size | `gatt_structs.dart:L93` | 9 | No usage yet (toBytes not implemented) |
| Dashboard placeholders | `dashboard_tab.dart:L31-36` | `'--'` × 6 | Hardcoded, to be replaced by live stream |
| Route `/device/:id` | `main.dart:L16` | `/device/:id` | `scanner_screen.dart:L80` (commented out, matching) |
| Permission matrix | `permission_guard.dart:L22-33` | role-based switch | No duplicates |
| authSessionProvider | `settings_screen.dart:L10` | StateNotifierProvider | Should move to shared provider file |

---

## 4. External References

| Topic | Industry Standard | Our Implementation | Gap |
|-------|------------------|-------------------|-----|
| BLE notification cleanup | `cancelWhenDisconnected()` before `setNotifyValue(true)` per flutter_blue_plus docs | Not called in `BleGatt.subscribe()` | **YES** — leak on disconnect |
| Dashboard stream binding | `ConsumerWidget` + `ref.watch()` + `AsyncValue.when()` per Riverpod docs | `StatelessWidget` with hardcoded `'--'` | **YES** — no live data |
| QosCtrl serialization | Symmetric `fromBytes()`/`toBytes()` pairs | Only `fromBytes()` exists | **YES** — can't write CTRL |
| Semantics annotations | All interactive elements need `Semantics(label:, hint:)`, min tap target 48×48 Android / 44×44 iOS | Zero annotations in entire codebase | **YES** — fails WCAG, blocks Appium |
| CTRL write confirmation | Write-with-response for control commands | `BleGatt.write()` uses confirmed writes | **OK** — matches standard |
| Navigation wiring | `context.go('/detail/:id')` standard GoRouter pattern | Commented out at L80 | **YES** — dead code |
| Error/loading states | `AsyncValue.when(loading:, error:, data:)` | No async handling in any tab | **YES** — no UX for loading/error |

**Sources:** [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus), [Punch Through BLE Write Guide](https://punchthrough.com/ble-write-requests-vs-write-commands/), [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility/accessibility-testing), [Appium Flutter Semantics](https://dev.to/arcymistrz/flutter-semantics-for-appium-testing-the-complete-guide-to-widget-accessibility-12e), [Riverpod StreamProvider](https://pub.dev/documentation/riverpod/latest/riverpod/StreamProvider-class.html)

---

## 5. Cross-cutting Concerns

### Config ↔ Code Conflicts
- **`authSessionProvider` location**: Config Worker found it defined in `settings_screen.dart:L10` (feature module), Code Map Worker confirmed ControlTab needs it for permission checks → must extract to shared provider file (e.g., `core/providers/auth_provider.dart`) to avoid cross-feature coupling

### Industry Standard ↔ Current Behavior Contradictions
- **`cancelWhenDisconnected()` missing**: External Worker flagged this as resource leak risk in `BleGatt.subscribe()`. Code Map Worker confirmed `subscribe()` at `ble_gatt.dart:L50-55` does NOT call it. This is out-of-scope for the 4 listed subtasks but should be noted as tech debt.
- **No `AsyncValue.when()` pattern**: External Worker recommends loading/error/data states; Code Map Worker confirms zero async state handling in dashboard_tab and control_tab.

### Test Fixture Gaps
- **No tests for scanner_screen, dashboard_tab, control_tab, scan_device_tile** — Code Map Worker confirmed
- **No `QosCtrl.toBytes()` test** — only `fromBytes()` is tested in `test/gatt_structs_test.dart`
- **No Riverpod `ProviderScope`** in existing `device_screen_test.dart` — will need it for new ConsumerWidget tests

### Worker Agreement
- All 3 workers independently identified `QosCtrl.toBytes()` as missing — **highest confidence finding**
- All 3 workers independently identified dashboard_tab StatelessWidget→ConsumerWidget conversion needed
- All 3 workers agree on the same must-change file list

### No Contradictions Between Workers
- File paths, line numbers, and function signatures are consistent across all 3 reports

---

## 6. Risks & Constraints

- **`QosCtrl.toBytes()` must be byte-level correct** — firmware expects exact 9-byte layout matching `fromBytes()` field order; wrong byte order = device malfunction
- **`connectedDeviceProvider.notifier.connect(device)` call sequence**: Someone must call this during scanner→device navigation BEFORE `statusStreamProvider`/`metricsStreamProvider` can subscribe. Code Map Worker flagged this as open question.
- **`QosMetricsV2` only has `raw: Uint8List`** with no decoded fields — DashboardTab may only need `QosStatus` fields (which are fully decoded). Planner must decide if `metricsStreamProvider` is needed in dashboard_tab at all.
- **`cancelWhenDisconnected()` not in scope** but is tech debt — notification subscriptions may leak on disconnect
- **No existing tests** for any of the 4 subtask target files — all test coverage is greenfield
- **pubspec.yaml** — no new dependencies needed (flutter_riverpod, go_router, mocktail all present)
- **CI** — `flutter analyze` + `flutter test` runs automatically on all files; no path filters

---

## 7. Recommendations for Plan

### Must Modify
- `lib/features/scanner/scanner_screen.dart` — uncomment `context.go()`, add `go_router` import, call `connectedDeviceProvider.notifier.connect(device)` before navigation
- `lib/features/device/dashboard/dashboard_tab.dart` — convert to `ConsumerWidget`, `ref.watch(statusStreamProvider)`, use `AsyncValue.when()` for loading/error/data, replace `'--'` with live `QosStatus` fields
- `lib/features/device/control/control_tab.dart` — convert to `ConsumerWidget`, implement CTRL write: `PermissionGuard.canWrite()` check → `QosCtrl.toBytes()` → `BleGatt.write(GattUuids.ctrl, bytes)`
- `lib/core/gatt/gatt_structs.dart` — add `QosCtrl.toBytes()` (mirror `QosGwCfgV2.toBytes()` pattern at L153)
- `lib/features/scanner/scan_device_tile.dart` — wrap with `Semantics(label:, hint:)` widget
- `lib/features/device/dashboard/dashboard_tab.dart` — add `Semantics` to `_MetricCard`

### Should Modify (Architectural Improvement)
- `lib/features/settings/settings_screen.dart` — extract `authSessionProvider` to `lib/core/providers/auth_provider.dart` (new file)

### Must NOT Modify
- `lib/core/gatt/gatt_uuids.dart` — SSOT for UUIDs, already clean, no changes needed
- `lib/core/providers/metrics_provider.dart` — already correctly wired with `autoDispose` streams
- `pubspec.yaml` — all dependencies already present

### Implementation Order Recommendation
1. **QosCtrl.toBytes()** first — prerequisite for CTRL write; pure logic, easy to TDD
2. **Extract authSessionProvider** — prerequisite for ControlTab (clean import path)
3. **Scanner navigation** — uncomment + import + connect call
4. **DashboardTab live data** — ConsumerWidget + stream subscription + AsyncValue.when()
5. **ControlTab CTRL write** — ConsumerWidget + permission check + BleGatt.write
6. **Semantics** — can be done in parallel or last; additive changes only

---

## 8. Knowledge Graph

### Key Entities
- `ScannerScreen` (widget) — Fleet overview, hosts ScanDeviceTile list
- `ScanDeviceTile` (widget) — Device list tile, needs Semantics
- `DashboardTab` (widget) — Telemetry display, currently StatelessWidget with hardcoded '--'
- `ControlTab` (widget) — QoS control operations, stub onTap
- `QosStatus` (class) — 13-byte STATUS characteristic struct, fully decoded fields
- `QosCtrl` (class) — 9-byte CTRL characteristic struct, missing `toBytes()`
- `QosMetricsV2` (class) — 20-byte METRICS characteristic struct, only raw bytes
- `BleGatt` (class) — BLE GATT read/write/subscribe operations
- `statusStreamProvider` (provider) — Auto-dispose stream of decoded QosStatus
- `metricsStreamProvider` (provider) — Auto-dispose stream of decoded QosMetricsV2
- `connectedDeviceProvider` (provider) — StateNotifier for connected device
- `PermissionGuard` (class) — Role-based write permission check
- `authSessionProvider` (provider) — Auth session state, mislocated in settings_screen
- `GattUuids` (class) — SSOT for all GATT UUID constants

### Key Relation Chains
1. **Navigation Chain:** `ScannerScreen._onDeviceTap` → `context.go('/device/:id')` → `DeviceScreen` → `DashboardTab` / `ControlTab`
2. **Live Data Chain:** `BleGatt.subscribe(GattUuids.status)` → `statusStreamProvider` → `DashboardTab.ref.watch()` → `_MetricCard` display
3. **CTRL Write Chain:** `ControlTab.onTap` → `PermissionGuard.canWrite()` → `QosCtrl.toBytes()` → `BleGatt.write(GattUuids.ctrl, bytes)`
4. **Device Connect Chain:** `scanner_screen.connect(device)` → `connectedDeviceProvider.notifier.connect()` → `metrics_provider` ref.watch → GATT subscription starts
5. **Accessibility Chain:** `ScanDeviceTile` → `Semantics(label, hint)` → screen reader / Appium test selectors

### Uncertainties / Conflicts
- **`QosMetricsV2` display strategy**: Only has `raw: Uint8List` with no decoded fields — unclear if DashboardTab should use `metricsStreamProvider` at all, or only `statusStreamProvider` (which has fully decoded fields). Medium confidence.
- **`cancelWhenDisconnected()` ownership**: External Worker recommends adding it to `BleGatt.subscribe()`, but it may belong at the provider level. Out of scope but flagged as tech debt.
- **`MergeSemantics` vs individual `Semantics`**: Low confidence on which pattern to use for MetricCard — depends on screen reader UX preference.
- **Dashboard metric field selection**: Only 6 of 10 QosStatus fields shown in current placeholder cards — unclear if this is intentional.
- **CTRL write confirmation dialog**: Whether to show UI confirmation before sending — domain decision, not technically mandated.

### Merged Graph
No `merged_graph.json` was produced by `tools/merge_research_graph.py`. Graph data is embedded in the 3 worker reports at:
- Code Map Worker: `/var/folders/.../w1-codemap.md` § Graph Extraction
- Config Worker: `/var/folders/.../w2-config.md` § Graph Extraction
- External Worker: `/var/folders/.../w3-external.md` § Graph Extraction
