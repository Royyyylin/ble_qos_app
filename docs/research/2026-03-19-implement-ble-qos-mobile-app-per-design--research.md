# Research Brief: BLE QoS Mobile App V2 Implementation
**Date:** 2026-03-19
**Task:** Implement BLE QoS Mobile App per design spec: theme, auth, capability system, scanner overhaul, device screen, provisioning, data layer (Drift/SQLite), CBOR codec
**Domain Model:** /Users/create94520/ble_qos_demo/ble_qos_demo_V1.2m/docs/superpowers/specs/2026-03-19-ble-qos-mobile-app-design.md

---

## 1. Existing Code Map

### BLE Scanner
- **Current location:** `lib/core/ble/ble_scanner.dart:L10`
- **Current behavior:** Basic scan with service UUID filter, produces `ScannedDevice` with id/name/rssi/mode only. No EMA smoothing, no manufacturer data parsing, no stale/offline state tracking, no duty-cycle management.
- **Key functions:** `BleScanner` — reads `GattUuids.serviceQos` for scan filter
- **Config source:** `lib/core/gatt/gatt_uuids.dart:L7` (service UUID `0x1820`)

### BLE Connector
- **Current location:** `lib/core/ble/ble_connector.dart:L11`
- **Current behavior:** Connect + PEER_ROLE handshake (writes `PeerRole.phone`). No capability negotiation step.
- **Key functions:** `BleConnector` — depends on `GattUuids.peerRole`, `PeerRole.phone`
- **Config source:** `lib/core/gatt/gatt_peer_role.dart:L4`

### BLE GATT
- **Current location:** `lib/core/ble/ble_gatt.dart:L10`
- **Current behavior:** Thin GATT read/write/subscribe wrapper over `BleConnector`.
- **Key functions:** `BleGatt(connector)` — used by `EngineerScreen`, `InstallerScreen`, metrics providers

### BLE Reconnect
- **Current location:** `lib/core/ble/ble_reconnect.dart:L6`
- **Current behavior:** 5-attempt auto-reconnect, 3s interval. Depends on `BleConnector`.

### Scanned Device Model
- **Current location:** `lib/core/ble/ble_models.dart:L4`
- **Current behavior:** `ScannedDevice` with id/name/rssi/mode only. `modeFromName()` uses hardcoded `'GW-'` prefix.
- **Key functions:** `ScannedDevice.modeFromName()` — hardcoded name prefix parsing

### GATT UUIDs
- **Current location:** `lib/core/gatt/gatt_uuids.dart:L3`
- **Current behavior:** Static UUID constants for QoS service characteristics. **Missing**: Capability UUID `6f8a9c19`, ED_COUNT/ED_LIST UUIDs.
- **Config source:** This IS the SSOT for UUID values

### GATT Structs (Binary Codecs)
- **Current location:** `lib/core/gatt/gatt_structs.dart:L8`
- **Current behavior:** Binary struct codecs for `QosStatus` (13B), `QosMetricsV2` (20B), `QosCtrl` (9B), `QosGwCfgV2`, `QosEvtV1`, `QosPingRsp`. Sizes hardcoded to match firmware SSOT (`src/qos_service.h`).

### Role Policy (Auth)
- **Current location:** `lib/core/domain/role_policy.dart:L5`
- **Current behavior:** `AppRole` enum with `patrol/installer/engineer`. `RolePolicy.canWrite()` — hardcoded permission matrix. No PIN validation, no lockout, no timeout.
- **Config source:** Hardcoded in `role_policy.dart:L17-34`

### Unlock Session
- **Current location:** `lib/core/domain/unlock_session.dart:L7`
- **Current behavior:** Fixed 60s session. No PIN validation, no failure lockout, no dual timeout (idle + absolute).

### Alarm Model
- **Current location:** `lib/core/domain/alarm_model.dart:L6`
- **Current behavior:** `AlarmEntry` + `AlarmHistory` — in-memory Queue, maxEntries=200. No persistence (no Drift/SQLite).

### App Entry Point
- **Current location:** `lib/main.dart:L1`
- **Current behavior:** `BleQosApp` — `MaterialApp` with named routes (7 screens), `colorSchemeSeed: Colors.indigo`. No GoRouter, no dark theme, no auth guard.

### Screens (7 total)
- `lib/features/device_list/device_list_screen.dart:L13` — `DeviceListScreen` — scan + navigate by mode
- `lib/features/home/gw_home_screen.dart:L12` — `GwHomeScreen` — GW status view, hardcoded tabs
- `lib/features/home/ed_home_screen.dart:L12` — `EdHomeScreen` — ED status view
- `lib/features/patrol/patrol_screen.dart:L14` — `PatrolScreen` — alarm history accumulation
- `lib/features/engineer/engineer_screen.dart:L19` — `EngineerScreen` — unlock/diagnostics/CTRL/GW_CFG/PING/CMD/PIN
- `lib/features/installer/installer_screen.dart:L12` — `InstallerScreen` — ROLE write + SET_MAX_ED
- `lib/features/settings/settings_screen.dart:L11` — `SettingsScreen` — role switch, disconnect

### Widgets
- `lib/widgets/metric_card.dart:L4` — `MetricCard` — label/value/unit card
- `lib/widgets/zone_indicator.dart:L4` — `ZoneIndicator` — zone color badge
- `lib/widgets/connection_banner.dart:L6` — `ConnectionBanner` — BLE state banner

---

## 2. Caller / Dependency Map

| Source | Calls | Via |
|--------|-------|-----|
| `main.dart:L4-10` | `DeviceListScreen`, `GwHomeScreen`, `EdHomeScreen`, `PatrolScreen`, `InstallerScreen`, `EngineerScreen`, `SettingsScreen` | route imports |
| `device_list_screen.dart:L39` | `bleScannerProvider`, `connectedDeviceProvider`, `bleConnectorProvider` | Riverpod ref.read |
| `gw_home_screen.dart:L19-20` | `connectedDeviceProvider`, `bleConnectorProvider`, `statusStreamProvider`, `evtStreamProvider` | Riverpod ref.watch |
| `ed_home_screen.dart:L19-20` | same as GwHomeScreen | Riverpod ref.watch |
| `patrol_screen.dart:L22-23` | `connectedDeviceProvider`, `statusStreamProvider`, `evtStreamProvider`, `alarmHistoryProvider` | Riverpod |
| `engineer_screen.dart:L32` | `BleGatt(connector)`, `unlockSessionProvider`, `appRoleProvider`, `statusStreamProvider`, `connectedDeviceProvider` | Riverpod + direct |
| `installer_screen.dart:L25` | `BleGatt(connector)`, `appRoleProvider`, `connectedDeviceProvider` | Riverpod + direct |
| `settings_screen.dart:L16-18` | `appRoleProvider`, `unlockSessionProvider`, `connectedDeviceProvider`, `bleConnectorProvider` | Riverpod |
| `metrics_provider.dart:L13-48` | `connectedDeviceProvider`, `bleConnectorProvider`, `BleGatt`, `GattUuids`, `QosStatus/QosEvtV1/QosMetricsV2.fromBytes` | imports |
| `ble_connector.dart:L62` | `GattUuids.peerRole`, `PeerRole.phone` | direct import |
| `ble_scanner.dart:L35` | `GattUuids.serviceQos` | direct import |

---

## 3. Config & SSOT Analysis

| Value | SSOT Location | Current Value | Duplicates/Hardcodes |
|-------|--------------|---------------|---------------------|
| App name | `pubspec.yaml:L1` | `ble_qos_app` | Hardcoded in `main.dart:L24` as `'BLE QoS Monitor'` |
| SDK constraint | `pubspec.yaml:L22` | `^3.11.1` | None |
| BLE dep | `pubspec.yaml:L34` | `flutter_blue_plus: ^1.35.0` | None |
| Service UUID | `gatt_uuids.dart:L7` | `00001820-...` (0x1820) | Read by `ble_scanner.dart:L35` (OK) |
| QoS struct sizes | `gatt_structs.dart` | `QosStatus.size=13, QosMetricsV2.size=20, QosCtrl.size=9` | Firmware SSOT: `src/qos_service.h` |
| Role enum | `role_policy.dart:L5-9` | `patrol/installer/engineer` | Spec says `Normal/Maintenance/Engineer` — **MISMATCH** |
| Permission matrix | `role_policy.dart:L17-34` | Hardcoded map | Spec §3.2 is SSOT — missing CTRL/GW_CFG for installer |
| Theme | `main.dart:L23-25` | `colorSchemeSeed: Colors.indigo` | Spec §8: Deep Navy `#0A0E1A` — **not implemented** |
| Routing | `main.dart:L28-36` | `MaterialApp.routes` map | Spec: GoRouter — **not implemented** |
| Device mode detection | `ble_models.dart:L20-23` | Hardcoded `'GW-'` prefix check | Should use capability negotiation |
| CI test cmd | `.orchestrate.yaml:L2` | `flutter test` | Also in `.github/workflows/ci.yml:L19` (both OK) |
| Capability UUID `6f8a9c19` | Spec §5.1 | **NOT DEFINED** in `gatt_uuids.dart` | Gap |
| ED_COUNT/ED_LIST UUIDs | Firmware `src/qos_service.h` | **NOT DEFINED** in `gatt_uuids.dart` | Gap |
| Font (JetBrains Mono) | Spec §8.2 | **NOT DECLARED** in pubspec.yaml, no `assets/fonts/` dir | Gap |

---

## 4. External References

| Topic | Industry Standard | Our Implementation | Gap |
|-------|------------------|-------------------|-----|
| Capability model | SmartThings: attribute/command, registry, healthCheck mandatory, graceful degradation | Spec aligns (attribute/command/registry/graceful degradation) | MINOR — add healthCheck as implicit capability |
| CBOR encoding | RFC 8949 (Internet Standard), 30-50% smaller than JSON | Spec uses CBOR — correct. Note: Matter uses TLV, not CBOR; spec's Matter attribution is inaccurate | NO — choice valid, fix attribution |
| RSSI EMA | α=0.05 for static, α=0.2-0.3 for responsive monitoring | Spec α=0.3 | NO — appropriate for real-time monitoring |
| BLE scan duty | Android BALANCED: 50% @ 2.56s; LOW_POWER: ~10% | Spec: 40% @ 5s (2s scan/3s pause) | NO — reasonable for foreground |
| Background scanning | PendingIntent + WorkManager | Stop scan (conservative) | NO — acceptable for Phase 1 |
| PIN security | OWASP: 6+ digits, 3-5 lockout attempts | Spec: 6-digit (L1), 8-digit (L2), 5 attempts | NO — compliant |
| PIN storage | OWASP: secure enclave or server-side | SharedPreferences (hashed) | YES — known limitation, Phase 2 plan |
| Session timeouts | OWASP: idle 15-30min, absolute 8h | L1: 15min/8h, L2: 5min/4h | NO — matches well |
| Schema evolution | Azure DTDL v3: minor = additive-only | Spec: additive-only strategy | NO — aligned |
| Schema migration testing | Drift: export + validateDatabaseSchema per version | Not mandated in spec | YES — should add migration tests |
| V1 scanner | Spec requires EMA, duty cycle, stale/offline | V1 has none | YES — major V1→V2 gap |
| V1 theme | Spec requires dark tech theme (#0A0E1A) | V1 uses Material indigo | YES — major V1→V2 gap |
| V1 routing | Spec requires GoRouter | V1 uses MaterialApp.routes | YES — structural gap |
| V1 deps | Spec requires cbor, drift, shared_preferences | V1 missing all 6 | YES — foundational gap |

---

## 5. Cross-cutting Concerns

### Config-Code Mismatches (Config Worker × Code Map Worker)
- **Role naming mismatch**: Config Worker found `role_policy.dart:L5-9` uses `patrol/installer/engineer`; spec SSOT says `Normal/Maintenance/Engineer` (Role-0/1/2). Code Map Worker confirms `AppRole` enum has the old names. This is a semantic mismatch — `patrol ≠ Normal`, `installer ≠ Maintenance`.
- **Permission matrix hardcoded**: Config Worker found `role_policy.dart:L17-34` has hardcoded permissions; Code Map Worker confirmed `RolePolicy.canWrite()` is the only consumer. Spec §3.2 expands permissions to include CTRL/GW_CFG for maintenance role.
- **Device mode hardcoded**: Config Worker found `ble_models.dart:L20-23` uses hardcoded `'GW-'` prefix; Code Map Worker found `DeviceListScreen` routes by `ConnectionMode`. Both should be replaced by capability negotiation.

### Industry Standard vs Current Code (External Worker × Code Map Worker)
- **EMA smoothing missing**: External Worker confirmed α=0.3 is appropriate; Code Map Worker confirmed `BleScanner` has zero EMA logic — complete gap.
- **No duty-cycle scanning**: External Worker found Android BALANCED at 50%; Code Map Worker confirmed scanner runs continuously — battery drain risk.
- **No healthCheck capability**: External Worker found SmartThings mandates healthCheck; Code Map Worker confirmed no capability system exists at all.

### Config Gaps Without Tests (Config Worker × Code Map Worker)
- **GattUuids missing Capability UUID**: Both workers flagged `6f8a9c19` missing. Code Map Worker confirmed no test covers UUID completeness.
- **No tests for BleScanner, BleConnector, BleGatt, BleReconnect, any screen, any provider** — Code Map Worker explicitly listed these gaps.
- **No migration tests for future Drift schema**: External Worker flagged this; no test infrastructure exists yet.

### Contradictions
- **None found** — all three workers agree on the factual state of the codebase. Minor differences in entity ID naming conventions (e.g., `ble_qos_app.core.gatt.GattUuids` vs `lib/core/gatt/gatt_uuids.dart:GattUuids`) are cosmetic.

### Gaps (No Worker Coverage)
- **Provisioning flow**: No worker deeply analyzed the firmware-side provisioning handshake sequence. The spec defines it, but no existing code implements it.
- **Audit log**: No existing code, no config, no external standard reference — entirely new feature.
- **i18n/l10n**: Spec mentions `intl` dependency but no worker analyzed localization requirements.

---

## 6. Risks & Constraints

- **Structural rewrite risk**: GoRouter + Drift + CBOR + Riverpod codegen + capability system + auth rewrite affects virtually every file. Incremental migration strategy needed to avoid big-bang breakage.
- **Font asset dependency**: JetBrains Mono must be bundled in `assets/fonts/` before pubspec can declare it. License compliance needed (OFL).
- **Build runner in CI**: Adding `drift`, `riverpod_annotation`, `riverpod_generator` requires `build_runner` step in CI pipeline (`.github/workflows/ci.yml`). Generated files must be committed or generated in CI.
- **SharedPreferences PIN storage is NOT a security boundary**: OWASP explicitly warns against client-side-only auth. Spec acknowledges this, but Phase 2 secure storage plan must be tracked.
- **Firmware struct size coupling**: `gatt_structs.dart` hardcodes byte sizes matching firmware `src/qos_service.h`. Any firmware change breaks the app. Consider adding size validation assertions.
- **Role rename is semantic, not cosmetic**: `patrol → Normal` is NOT a 1:1 rename — the permission sets differ. Existing `role_policy_test.dart` tests will need full rewrite, not just name changes.
- **Matter attribution inaccuracy**: Spec references "Matter 標準" for CBOR, but Matter uses TLV. CBOR choice is valid (RFC 8949) but documentation should be corrected.

---

## 7. Recommendations for Plan

### Build Order (dependency-aware)
1. **Foundation first**: `pubspec.yaml` (add deps), `app_theme.dart`, `app_colors.dart` — zero existing callers, safe to add
2. **Data layer**: `database.dart`, `tables/`, `repositories/` (Drift) — new files, no existing deps
3. **Domain models**: `device_model.dart`, `telemetry_model.dart`, `alert_model.dart`, `audit_model.dart` — new files
4. **Auth system**: `auth_session.dart`, `pin_validator.dart`, `permission_guard.dart` — replaces `role_policy.dart` + `unlock_session.dart`
5. **CBOR codec**: `cbor_codec.dart` — new file, no existing deps
6. **Capability system**: `capability_model.dart`, `capability_registry.dart`, `capability_negotiator.dart` — new files
7. **Scanner overhaul**: Modify `ble_scanner.dart`, `ble_models.dart` — existing callers must update
8. **Connector update**: Modify `ble_connector.dart` — add capability negotiation
9. **Provider layer**: New providers (`scan_provider.dart`, `connection_provider.dart`, `auth_provider.dart`, `telemetry_provider.dart`, `capability_provider.dart`) — replaces existing providers
10. **Routing**: Replace `MaterialApp.routes` with GoRouter in `main.dart`
11. **Screens**: New `scanner/`, `device/`, `provisioning/`, `audit/` screens — replace old screens
12. **Delete deprecated**: `gw_home_screen.dart`, `ed_home_screen.dart`, `device_list_screen.dart`

### Files that MUST be modified
- `pubspec.yaml` — add cbor, drift, sqlite3_flutter_libs, shared_preferences, intl, riverpod_annotation, riverpod_generator, build_runner, drift_dev; add fonts section
- `lib/main.dart` — GoRouter, dark theme, auth guard
- `lib/core/ble/ble_scanner.dart` — EMA, duty-cycle, stale/offline, manufacturer data
- `lib/core/ble/ble_connector.dart` — capability negotiation
- `lib/core/ble/ble_models.dart` — expand ScannedDevice
- `lib/core/gatt/gatt_uuids.dart` — add Capability UUID, ED_COUNT, ED_LIST
- `lib/core/domain/role_policy.dart` — rewrite to 3-tier
- `lib/core/domain/unlock_session.dart` — rewrite for dual timeout + lockout
- `.github/workflows/ci.yml` — add build_runner step
- `analysis_options.yaml` — consider stricter lints

### Files that MUST NOT be modified
- `lib/core/gatt/gatt_structs.dart` — binary struct codecs match firmware; only extend, don't change existing fromBytes()
- `lib/core/gatt/gatt_peer_role.dart` — PeerRole enum is firmware-defined
- `lib/core/ble/ble_reconnect.dart` — reconnect logic is stable, only needs connector interface update

### Additional Recommendations
- **Mandate Drift migration tests** (export schema per version, `validateDatabaseSchema`)
- **Add healthCheck as implicit capability** (SmartThings best practice)
- **Make alert flapping suppression window configurable** (currently 5min hardcoded in spec)
- **Use capability version format major.minor** (not just integer) for future-proofing
- **Correct Matter/CBOR attribution** in documentation

---

## 8. Knowledge Graph

### Key Entities
- `BleScanner` (class) — basic scan, needs EMA/duty-cycle/stale overhaul
- `BleConnector` (class) — handshake only, needs capability negotiation
- `BleGatt` (class) — thin GATT wrapper, stable
- `GattUuids` (class) — UUID constants, missing Capability/ED_COUNT/ED_LIST
- `AppRole` (enum) — patrol/installer/engineer, must be rewritten to Role-0/1/2
- `RolePolicy` (class) — hardcoded permissions, must match spec §3.2
- `UnlockSession` (class) — 60s fixed, must be rewritten for dual timeout + lockout
- `AlarmHistory` (class) — in-memory Queue, must move to Drift persistence
- `pubspec.yaml` (config) — SSOT for deps, missing 6 required packages
- `.github/workflows/ci.yml` (config) — needs build_runner step
- `smartthings.capability_model` (external) — validates spec capability pattern
- `owasp.masvs_auth` (external) — validates spec auth parameters
- `rfc8949.cbor` (external) — validates CBOR choice
- `drift.migration_testing` (external) — identifies spec gap in migration tests

### Key Relation Chains
- `pubspec.yaml` → defines → `main.dart` → routes → `DeviceListScreen` → depends_on → `BleScanner` → depends_on → `GattUuids` (adding deps cascades through routing to scanner)
- `AppRole` → defines → `RolePolicy` → gates → `EngineerScreen`/`InstallerScreen` (role rewrite affects all gated screens)
- `BleConnector` → depends_on → `GattUuids` + `PeerRole` → used_by → `BleGatt` → used_by → `metrics_provider` → feeds → all home/status screens (connector change ripples to all data views)
- `smartthings.capability_model` → validates → spec capability system → will_replace → `ConnectionMode` hardcoded routing (external validates the architecture pivot from hardcoded to capability-driven)
- `owasp.masvs_auth` → validates → spec auth → will_replace → `UnlockSession` + `AppRole` (external validates security redesign)

### Uncertainties / Conflicts
- **Role rename semantics**: Is `patrol → Normal` a direct rename or a semantic change? Workers agree the names differ but the permission mapping is ambiguous (patrol had read-only; Normal in spec also read-only — may be equivalent after all).
- **Incremental vs rewrite**: Code Map Worker flagged this as a decision point. The scope of changes (GoRouter + Drift + CBOR + capabilities + auth + theme) touches every file — unclear if incremental migration is practical.
- **Build runner outputs**: Config Worker flagged medium confidence on whether generated files should be committed or generated in CI. This affects CI workflow design.

### Merged Graph
No `merged_graph.json` was produced by `tools/merge_research_graph.py`. Graph data above is manually synthesized from all three worker reports' Graph Extraction sections.
