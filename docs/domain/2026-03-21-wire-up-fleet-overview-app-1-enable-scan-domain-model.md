# Domain Model: Wire Up Fleet Overview App
**Date:** 2026-03-21
**Task:** Wire up Fleet Overview app: 1) Enable scanner→device navigation (uncomment context.go in scanner_screen.dart), 2) Subscribe dashboard_tab to live STATUS/METRICS GATT notify streams replacing hardcoded '--' values, 3) Implement CTRL write onTap in control_tab.dart using ble_gatt.write(), 4) Add Semantics widgets to ScanDeviceTile and key interactive elements for accessibility/automation testing.

---

## Event Storming

### Domain Events
| Event | Command | Actor | Policy |
|-------|---------|-------|--------|
| DeviceTapped | TapDevice | User | "When DeviceTapped, navigate to /device/:id via GoRouter" |
| DeviceConnected | Connect | BleConnector | "When DeviceConnected, set connectedDeviceProvider state" |
| StatusNotificationReceived | SubscribeStatus | GattNotifyStream | "When StatusNotificationReceived, decode QosStatus and update UI" |
| MetricsNotificationReceived | SubscribeMetrics | GattNotifyStream | "When MetricsNotificationReceived, decode QosMetricsV2 and update UI" |
| CtrlWriteRequested | WriteCtrl | User | "When CtrlWriteRequested, check PermissionGuard.canWrite first" |
| CtrlWriteAuthorized | AuthorizeWrite | PermissionGuard | "When CtrlWriteAuthorized, serialize QosCtrl and call BleGatt.write()" |
| CtrlWritten | WriteGatt | BleGatt | "When CtrlWritten, show success snackbar" |
| CtrlWriteFailed | WriteGatt | BleGatt | "When CtrlWriteFailed, show error snackbar" |
| PermissionDenied | AuthorizeWrite | PermissionGuard | "When PermissionDenied, show auth elevation prompt" |
| SemanticsAnnotated | — | Developer | — |

---

## Bounded Contexts

### Navigation Context
**Responsibility:** Route user from Fleet Overview (scanner) to Device Detail screen via GoRouter.

#### Aggregates
- **ScannedDevice** (existing) — invariants: must have valid `id` (BLE remoteId) to navigate
  - Entities: ScannedDevice (identity = remoteId string)
  - Value Objects: DeviceStatus, ManufacturerData

#### Domain Services
- **None new** — navigation is a UI concern delegated to GoRouter. ConnectedDeviceNotifier (existing) tracks selected device state.

#### Repository Interfaces
- None (stateless navigation)

#### Domain Events (owned by this context)
- **DeviceTapped** — fields: `deviceId: String`

---

### Telemetry Context
**Responsibility:** Subscribe to live GATT STATUS/METRICS notify streams and present decoded telemetry on DashboardTab.

#### Aggregates
- **QosStatus** (existing Value Object, promoted to read-model) — invariants: exactly 13 bytes from firmware; zone ∈ {0,1,2,3}; profile ∈ {0,1,2}; pdr ∈ [0,100]
  - Value Objects: zone (uint8), profile (uint8), phy (uint8), txPower (int8), rssi (int8), pdr (uint8), interval (uint16), latency (uint16), jitter (uint16), tp (uint8)
- **QosMetricsV2** (existing Value Object) — invariants: exactly 20 bytes raw payload
  - Value Objects: raw (Uint8List)

#### Domain Services
- **BleGatt** (existing) — `subscribe(charUuid)` returns `Stream<Uint8List>` for STATUS/METRICS characteristics

#### Repository Interfaces
- None (real-time stream, no persistence in this scope)

#### Domain Events (owned by this context)
- **StatusNotificationReceived** — fields: `QosStatus` (decoded from 13-byte payload)
- **MetricsNotificationReceived** — fields: `QosMetricsV2` (decoded from 20-byte payload)

#### Existing Providers (Riverpod — Application Layer)
- **statusStreamProvider** — `StreamProvider.autoDispose<QosStatus>` (already wired in metrics_provider.dart)
- **metricsStreamProvider** — `StreamProvider.autoDispose<QosMetricsV2>` (already wired in metrics_provider.dart)
- **connectedDeviceProvider** — `StateNotifierProvider<ConnectedDeviceNotifier, ConnectedDevice?>` (device_provider.dart)

---

### Control Context
**Responsibility:** Authorize and execute CTRL characteristic writes to connected device.

#### Aggregates
- **QosCtrl** (existing Value Object) — invariants: exactly 9 bytes; profile ∈ {0,1,2}; phy ∈ {1,2,4,5}
  - Value Objects: profile (uint8), phy (uint8), txPower (int8), interval (uint16), creditAlarm (uint8), creditCtrl (uint8), creditRs485 (uint8), flags (uint8)

#### Domain Services
- **PermissionGuard** (existing) — `canWrite(AuthRole, GattAction.ctrl)` → bool. Requires maintenance+ role.
- **BleGatt** (existing) — `write(GattUuids.ctrl, bytes)` sends CTRL payload to firmware

#### Repository Interfaces
- None (write-through to firmware via GATT)

#### Domain Events (owned by this context)
- **CtrlWriteRequested** — fields: `QosCtrl` (parameters to write)
- **CtrlWritten** — fields: `deviceId: String`
- **CtrlWriteFailed** — fields: `deviceId: String`, `error: String`
- **PermissionDenied** — fields: `requiredRole: AuthRole`, `currentRole: AuthRole`

#### Implementation Gap
- **QosCtrl.toBytes()** — does NOT exist yet. Only `fromBytes()` is implemented. Must add serialization method to write CTRL values to firmware.

---

### Accessibility Context
**Responsibility:** Annotate interactive widgets with Semantics for screen readers and automation testing (Flutter `Semantics` widget).

#### Aggregates
- None (cross-cutting concern applied to existing widgets)

#### Domain Services
- None

#### Key Widgets Requiring Semantics
- **ScanDeviceTile** — label: device name + role + RSSI + status; hint: "Double tap to connect"
- **Scan toggle button** (AppBar) — label: "Start/Stop scan"
- **Search field** — already has hintText, may need explicit semanticsLabel
- **MetricCard** (DashboardTab) — label: "{metric}: {value} {unit}"
- **CTRL write button** (ControlTab) — label: "Write control command"; hint: permission status

---

## Context Map

| From | To | Relationship | Notes |
|------|----|-------------|-------|
| Navigation | Telemetry | Published Language | Navigation passes `deviceId` string; Telemetry uses `connectedDeviceProvider` to resolve |
| Navigation | Control | Published Language | Same `deviceId` string passed via GoRouter path parameter |
| Telemetry | GATT Protocol | ACL | `statusStreamProvider` / `metricsStreamProvider` translate raw `Uint8List` → `QosStatus` / `QosMetricsV2` via `fromBytes()` |
| Control | GATT Protocol | ACL | `QosCtrl.toBytes()` (to be added) serializes domain model → firmware binary format |
| Control | Auth | Shared Kernel | `PermissionGuard.canWrite(role, GattAction.ctrl)` shared between Control and Auth contexts |
| Accessibility | Navigation | Upstream/Downstream | Semantics wraps existing Navigation widgets (ScanDeviceTile) |
| Accessibility | Telemetry | Upstream/Downstream | Semantics wraps existing Telemetry widgets (MetricCard) |
| Accessibility | Control | Upstream/Downstream | Semantics wraps existing Control widgets (CTRL write button) |

---

## Ubiquitous Language Glossary

| Term | Definition | Context | Code Name |
|------|-----------|---------|-----------|
| Fleet Overview | The scanner screen showing all discovered BLE QoS devices grouped by network | Navigation | `ScannerScreen` |
| ScannedDevice | A BLE device discovered during scanning, identified by remoteId | Navigation | `ScannedDevice` (Entity in ble_models.dart) |
| DeviceScreen | The tabbed detail view for a connected device | Navigation | `DeviceScreen` (Widget) |
| GoRouter | Declarative routing framework used for scanner→device navigation | Navigation | `GoRouter` / `context.go()` |
| ConnectedDevice | State object tracking the currently connected device's id, name, and mode | Navigation | `ConnectedDevice` (device_provider.dart) |
| QosStatus | 13-byte firmware struct containing real-time telemetry (zone, RSSI, PDR, etc.) | Telemetry | `QosStatus` (Value Object in gatt_structs.dart) |
| QosMetricsV2 | 20-byte firmware struct containing extended metrics payload | Telemetry | `QosMetricsV2` (Value Object in gatt_structs.dart) |
| STATUS characteristic | GATT characteristic UUID 0x2A1D that notifies QosStatus updates | Telemetry | `GattUuids.status` |
| METRICS characteristic | GATT characteristic UUID 0x2A23 that notifies QosMetricsV2 updates | Telemetry | `GattUuids.metricsV2` |
| DashboardTab | Widget displaying decoded telemetry metrics in a grid of MetricCards | Telemetry | `DashboardTab` |
| MetricCard | Reusable card widget showing a single metric label, value, and unit | Telemetry | `_MetricCard` (private in dashboard_tab.dart) |
| statusStreamProvider | Riverpod StreamProvider that subscribes to STATUS notify and yields QosStatus | Telemetry | `statusStreamProvider` (metrics_provider.dart) |
| metricsStreamProvider | Riverpod StreamProvider that subscribes to METRICS notify and yields QosMetricsV2 | Telemetry | `metricsStreamProvider` (metrics_provider.dart) |
| QosCtrl | 9-byte firmware struct for writing control parameters (profile, PHY, TX power, etc.) | Control | `QosCtrl` (Value Object in gatt_structs.dart) |
| CTRL characteristic | GATT characteristic UUID 0x2A21 that accepts QosCtrl write commands | Control | `GattUuids.ctrl` |
| BleGatt | Thin wrapper providing read/write/subscribe operations over discovered GATT services | Telemetry, Control | `BleGatt` (ble_gatt.dart) |
| PermissionGuard | Static permission matrix checking AuthRole against GattAction | Control | `PermissionGuard` (permission_guard.dart) |
| GattAction | Enum of GATT operations requiring permission checks | Control | `GattAction` (permission_guard.dart) |
| AuthRole | Three-tier role enum: viewer, maintenance, engineer | Control | `AuthRole` (auth_session.dart) |
| ScanDeviceTile | List tile widget for a scanned device in the fleet overview | Navigation, Accessibility | `ScanDeviceTile` (scan_device_tile.dart) |
| Semantics | Flutter widget providing accessibility metadata for screen readers and test automation | Accessibility | `Semantics` (Flutter framework) |
| BleConnector | Manages BLE connection lifecycle and PEER_ROLE handshake | Navigation, Telemetry | `BleConnector` (ble_connector.dart) |
