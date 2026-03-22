# Domain Model: Device Identity Migration + BLE Scan Lifecycle + Capability Compat Matrix
**Date:** 2026-03-22
**Task:** Implement device identity migration (App-generated UUIDv4 stable ID replacing MAC as primary key across 9 touch points), BLE scan lifecycle (visible scan + TTL eviction + task-scoped connection + exponential backoff reconnect), and capability-driven compat matrix (negotiation read order + graceful degradation UI).

---

## Event Storming

### Domain Events
| Event | Command | Actor | Policy |
|-------|---------|-------|--------|
| DeviceFirstSeen | ProcessScanResult | BleScanner | "When DeviceFirstSeen, generate StableId via DeviceIdentityService and persist mapping" |
| StableIdAssigned | AssignStableId | DeviceIdentityService | "When StableIdAssigned, store MAC→StableId mapping in IdentityRepository" |
| DeviceReidentified | ProcessScanResult | BleScanner | "When scan result arrives for known MAC, resolve to existing StableId" |
| ScanStarted | StartScan | User / ScannerScreen | — |
| ScanStopped | StopScan | User / NavigateAway | — |
| DeviceAdvertisementReceived | ProcessScanResult | BleScanner | "When received, update lastSeen + RSSI EMA" |
| DeviceBecameStale | CheckTTL | TTLTimer | "When stale threshold (10s) crossed, update status to stale" |
| DeviceEvicted | EvictDevice | TTLTimer | "When offline threshold (30s) crossed, remove from visible list" |
| ConnectionRequested | ConnectToDevice | User / ScanDeviceTile | "When ConnectionRequested, stop scan (task-scoped scan lifecycle)" |
| ConnectionEstablished | Connect | BleConnector | "When ConnectionEstablished, perform PEER_ROLE handshake then read capabilities" |
| HandshakeCompleted | PerformHandshake | BleConnector | "When HandshakeCompleted, trigger CapabilityNegotiation" |
| UnexpectedDisconnection | — | BleStack | "When UnexpectedDisconnection, start exponential backoff reconnect" |
| ReconnectAttempted | Reconnect | BleReconnect | — |
| ReconnectSucceeded | Reconnect | BleReconnect | "When ReconnectSucceeded, re-read capabilities" |
| ReconnectGaveUp | — | BleReconnect | "When maxAttempts reached, show error + manual retry" |
| CapabilityCharRead | ReadCapabilities | BleGatt | "When read succeeds, negotiate against local registry" |
| CapabilityCharAbsent | ReadCapabilities | BleGatt | "When char absent, use role-based fallback caps" |
| CapabilityNegotiated | NegotiateCapabilities | CapabilityNegotiator | "When negotiated, enable/disable tabs + show degradation badges" |
| IncompatibleCapDetected | NegotiateCapabilities | CapabilityNegotiator | "When incompatible, show degradation UI (badge + tooltip)" |

---

## Bounded Contexts

### 1. Device Identity Context
**Responsibility:** Assign and resolve stable UUIDv4 identities for BLE devices, decoupling app-layer identity from platform-specific MAC addresses.

#### Aggregates
- **DeviceIdentity** — invariants: (1) each MAC maps to exactly one StableId, (2) StableId is UUIDv4 and immutable once assigned, (3) MAC-to-StableId mapping is persisted across sessions
  - Entities: —
  - Value Objects: `StableId` (UUIDv4 string), `MacAddress` (BLE remoteId string)

#### Domain Services
- **DeviceIdentityService** — resolves MAC→StableId (lookup or generate+persist); single entry point for all 9 touch points to obtain stable identity

#### Repository Interfaces
- **IdentityRepository** — `findByMac(String mac) → StableId?`, `findByStableId(String stableId) → MacAddress?`, `save(DeviceIdentity)`, `getAll() → List<DeviceIdentity>`

#### Domain Events (owned by this context)
- **StableIdAssigned** — fields: stableId, mac, assignedAt

#### Migration Touch Points (9 points where MAC→StableId)
| # | Touch Point | Current Code | Migration |
|---|-------------|-------------|-----------|
| 1 | `ScannedDevice.id` | BLE remoteId (MAC) | Resolve via IdentityService; `id` becomes StableId |
| 2 | `BleScanner._devices` map key | MAC string | Key by StableId, carry MAC as secondary field |
| 3 | `ConnectedDevice.id` | BLE remoteId | StableId; add `mac` field for BLE operations |
| 4 | `BleConnector.connect(deviceId)` | MAC | Accept StableId, resolve to MAC for FlutterBluePlus |
| 5 | `BleReconnect.startReconnect(deviceId)` | MAC | Accept StableId, resolve to MAC internally |
| 6 | `Devices` table PK (`id`) | MAC | StableId as PK; add `mac` column |
| 7 | `DeviceRepository.upsertDevice(id:)` | MAC | StableId |
| 8 | Navigation route parameter (GoRouter) | MAC | StableId |
| 9 | `connectedDeviceProvider` state | MAC | StableId; carry MAC for BLE layer |

---

### 2. BLE Scan Lifecycle Context
**Responsibility:** Manage the visible device list through scan start/stop, TTL-based status transitions, and eviction of gone devices.

#### Aggregates
- **ScanSession** — invariants: (1) only one active scan at a time, (2) devices transition online→stale→evicted monotonically unless re-advertised, (3) scan stops when connection is initiated (task-scoped)
  - Entities: `VisibleDevice` (a ScannedDevice within a scan session, tracked by StableId)
  - Value Objects: `DeviceStatus` (online/stale/offline enum), `SmoothedRssi` (EMA double), `ScanConfig` (scanWindow, pauseWindow, dutyCycle bool)

#### Domain Services
- **TTLEvictionService** — periodic check that transitions device statuses and removes devices past offline threshold from the visible list

#### Repository Interfaces
- *None* — scan state is in-memory only (not persisted)

#### Domain Events (owned by this context)
- **DeviceAdvertisementReceived** — fields: stableId, mac, rssi, mfgData, timestamp
- **DeviceBecameStale** — fields: stableId, elapsedSinceLastSeen
- **DeviceEvicted** — fields: stableId, reason (TTL expired)
- **ScanStarted** — fields: scanMode (continuous/dutyCycle)
- **ScanStopped** — fields: reason (userAction/connectionInitiated)

---

### 3. BLE Connection Lifecycle Context
**Responsibility:** Manage task-scoped connections with handshake, unexpected disconnection detection, and exponential backoff reconnect.

#### Aggregates
- **Connection** — invariants: (1) only one active connection at a time, (2) handshake (PEER_ROLE write) must complete before connected state, (3) reconnect only triggers on unexpected disconnection, not intentional disconnect, (4) reconnect respects maxAttempts cap
  - Entities: —
  - Value Objects: `BleConnectionState` (disconnected/connecting/handshaking/connected/error), `BackoffConfig` (baseDelay, maxDelay, maxAttempts), `ConnectionMode` (gwAggregate/edDirect)

#### Domain Services
- **HandshakeService** — writes PEER_ROLE characteristic after connection, transitions state to connected

#### Repository Interfaces
- *None* — connection state is transient

#### Domain Events (owned by this context)
- **ConnectionEstablished** — fields: stableId, mac
- **HandshakeCompleted** — fields: stableId, peerRoleWritten
- **UnexpectedDisconnection** — fields: stableId, mac, previousState
- **ReconnectAttempted** — fields: stableId, attemptNumber, delay
- **ReconnectSucceeded** — fields: stableId, totalAttempts
- **ReconnectGaveUp** — fields: stableId, totalAttempts

---

### 4. Capability Negotiation Context
**Responsibility:** Read device capabilities via GATT, negotiate against local registry, determine enabled features, and surface degradation information to UI.

#### Aggregates
- **DeviceCapabilitySet** — invariants: (1) capabilities read from GATT CAPABILITY char first, fallback to role-based defaults if absent, (2) negotiation produces definitive enabled/incompatible/unknown lists, (3) incompatible caps trigger degradation UI rather than hiding
  - Entities: —
  - Value Objects: `Capability` (id + version), `NegotiationResult` (enabledTabs, incompatible, unknown), `DegradationInfo` (capId, deviceVersion, requiredVersion, degradedMessage)

#### Domain Services
- **CapabilityNegotiator** — static negotiation: iterate device caps against registry, classify each as enabled/incompatible/unknown
- **CapabilityRegistry** — maps capId→CapabilityHandler (tabLabel + minVersion); provides role-based fallback

#### Read Order (negotiation sequence)
| Step | Action | Fallback |
|------|--------|----------|
| 1 | Read CAPABILITY char (6f8a9c19) | If absent or read fails → step 2 |
| 2 | Parse ManufacturerData.role from scan | Use `CapabilityRegistry.fallbackForRole(role)` |
| 3 | Negotiate parsed caps against registry | Produce `NegotiationResult` |
| 4 | Apply UI: enable tabs, show degradation badges | — |

#### Graceful Degradation Rules
| Condition | UI Behavior |
|-----------|-------------|
| Cap known + version ≥ minVersion | Tab enabled, no badge |
| Cap known + version < minVersion | Tab enabled with warning badge + tooltip showing version mismatch |
| Cap unknown (not in registry) | Ignored; logged for telemetry |
| CAPABILITY char absent | Role-based fallback caps used transparently |
| All caps incompatible | Show "limited mode" banner on device screen |

#### Repository Interfaces
- *None* — capabilities are read live from GATT per connection

#### Domain Events (owned by this context)
- **CapabilityNegotiated** — fields: stableId, enabledTabs, incompatibleCaps, unknownCaps
- **IncompatibleCapDetected** — fields: stableId, capId, deviceVersion, requiredMinVersion

---

## Context Map

| From | To | Relationship | Notes |
|------|----|-------------|-------|
| BLE Scan Lifecycle | Device Identity | ACL | Scanner resolves MAC→StableId via DeviceIdentityService before emitting VisibleDevice |
| BLE Connection Lifecycle | Device Identity | ACL | Connector accepts StableId, resolves to MAC for FlutterBluePlus operations |
| BLE Connection Lifecycle | BLE Scan Lifecycle | Published Language | ConnectionRequested event causes ScanStopped (task-scoped lifecycle) |
| Capability Negotiation | BLE Connection Lifecycle | Shared Kernel | Shares connected device reference; reads GATT only when connected |
| Capability Negotiation | Device Identity | ACL | Uses StableId to tag negotiation results |

---

## Ubiquitous Language Glossary

| Term | Definition | Context | Code Name |
|------|-----------|---------|-----------|
| StableId | App-generated UUIDv4 that uniquely identifies a device across sessions, replacing MAC as primary key | Device Identity | `StableId` (Value Object) |
| MacAddress | Platform-specific BLE remote identifier (typically MAC address), used only for BLE stack operations | Device Identity | `MacAddress` (Value Object), current `remoteId` |
| DeviceIdentity | The mapping between a device's MAC address and its stable UUIDv4 identity | Device Identity | `DeviceIdentity` (Aggregate Root) |
| IdentityRepository | Persistence interface for MAC↔StableId mappings | Device Identity | `IdentityRepository` |
| DeviceIdentityService | Resolves or assigns stable IDs for BLE devices seen during scanning | Device Identity | `DeviceIdentityService` |
| ScanSession | An active BLE scanning session with its visible device list and TTL tracking | BLE Scan Lifecycle | `ScanSession` / `BleScanner` |
| VisibleDevice | A BLE device currently in the scan list with status tracking | BLE Scan Lifecycle | `ScannedDevice` (existing) |
| DeviceStatus | Tri-state status of a scanned device: online, stale, or offline | BLE Scan Lifecycle | `DeviceStatus` (enum, existing) |
| TTL Eviction | Automatic removal of devices from the visible list when offline threshold is exceeded | BLE Scan Lifecycle | `_updateDeviceStatuses()` / `TTLEvictionService` |
| Task-Scoped Scan | Scan automatically stops when a connection is initiated and resumes when returning to scanner | BLE Scan Lifecycle | scan stop on `ConnectionRequested` |
| Duty Cycle | Scan power optimization: scan for scanWindow, pause for pauseWindow, repeat | BLE Scan Lifecycle | `dutyCycle` param, `scanWindow`, `pauseWindow` |
| Connection | A BLE connection lifecycle from connect through handshake to connected state | BLE Connection Lifecycle | `BleConnector` (existing) |
| Handshake | PEER_ROLE write (0x02 = Phone) performed after BLE connection before entering connected state | BLE Connection Lifecycle | `_performHandshake()` (existing) |
| BackoffConfig | Exponential backoff parameters: baseDelay, maxDelay, maxAttempts | BLE Connection Lifecycle | `BackoffConfig` (existing Value Object) |
| BleConnectionState | State machine for connection: disconnected → connecting → handshaking → connected / error | BLE Connection Lifecycle | `BleConnectionState` (existing enum) |
| ConnectionMode | Whether the phone connects to a GW (aggregate) or directly to an ED | BLE Connection Lifecycle | `ConnectionMode` (existing enum) |
| UnexpectedDisconnection | A disconnection not initiated by the user, triggering auto-reconnect | BLE Connection Lifecycle | `_intentionalDisconnect == false` (existing) |
| Capability | A device feature identified by string ID and integer version | Capability Negotiation | `Capability` (existing Value Object) |
| CapabilityHandler | Registry entry mapping a capability ID to its UI tab and minimum supported version | Capability Negotiation | `CapabilityHandler` (existing) |
| NegotiationResult | Output of capability negotiation: enabled tabs, incompatible caps, unknown caps | Capability Negotiation | `NegotiationResult` (existing) |
| DegradationInfo | Metadata about an incompatible capability shown as a warning badge in the UI | Capability Negotiation | `DegradationInfo` (new Value Object) |
| Graceful Degradation | UI pattern where incompatible capabilities show warning badges instead of being hidden | Capability Negotiation | degradation badge + tooltip |
| Role-Based Fallback | Default capabilities assigned by device role when CAPABILITY char is absent | Capability Negotiation | `CapabilityRegistry.fallbackForRole()` (existing) |
