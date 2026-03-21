# Domain Model: Remaining Device Screen Features
**Date:** 2026-03-21
**Task:** Implement remaining Device Screen features: (1) Provisioning ROLE write via GATT, (2) HA Tab heartbeat subscription and display, (3) Admin Tab ENG_UNLOCK PIN entry, (4) Admin Tab CMD reboot, (5) Admin Tab MODE/ROLE write.

---

## Event Storming

### Domain Events
| Event | Command | Actor | Policy |
|-------|---------|-------|--------|
| RoleWriteRequested | SubmitProvisioningForm | Engineer | "When RoleWriteRequested, show confirmation dialog with reboot warning" |
| RoleWriteConfirmed | ConfirmProvisioningDialog | Engineer | "When RoleWriteConfirmed, write ROLE characteristic (0x2A1F) with uint8 role value" |
| RoleWritten | — (GATT response) | Firmware | "When RoleWritten, show success snackbar; device will reboot and disconnect" |
| RoleWriteFailed | — (GATT error) | Firmware | "When RoleWriteFailed, show error snackbar with retry option" |
| DeviceRebootedAfterProvision | — (disconnect event) | Firmware | "When DeviceRebootedAfterProvision, navigate back to scanner screen" |
| HaHeartbeatSubscribed | SubscribeHaHeartbeat | DeviceScreen | "When connected and HA capability present, auto-subscribe to HA_HB notify" |
| HaHeartbeatReceived | — (GATT notify) | Firmware | "When HaHeartbeatReceived, parse 21-byte payload and update HA display" |
| EngUnlockRequested | TapEngUnlock | Engineer | "When EngUnlockRequested, show PIN entry dialog" |
| EngPinSubmitted | SubmitEngPin | Engineer | "When EngPinSubmitted, write ENG_UNLOCK characteristic (6f8a9c11) with ASCII PIN" |
| EngUnlockSucceeded | — (GATT response) | Firmware | "When EngUnlockSucceeded, elevate AuthSession to engineer role" |
| EngUnlockFailed | — (GATT response) | Firmware | "When EngUnlockFailed, show error dialog with remaining attempts" |
| CmdRebootRequested | TapCmdReboot | Engineer | "When CmdRebootRequested, check ENG_UNLOCK state first" |
| CmdRebootConfirmed | ConfirmRebootDialog | Engineer | "When CmdRebootConfirmed, write CMD characteristic (0x2A20) with 0x01" |
| DeviceRebooted | — (disconnect event) | Firmware | "When DeviceRebooted, navigate back to scanner screen" |
| ModeWriteRequested | SelectModeValue | Engineer | "When ModeWriteRequested, show confirmation dialog" |
| ModeWriteConfirmed | ConfirmModeDialog | Engineer | "When ModeWriteConfirmed, write MODE characteristic (0x2A1E) with uint8 value" |
| ModeWritten | — (GATT response) | Firmware | "When ModeWritten, show success feedback" |
| AdminRoleWriteRequested | SelectRoleValue | Engineer | "When AdminRoleWriteRequested, show confirmation dialog with reboot warning" |
| AdminRoleWriteConfirmed | ConfirmRoleDialog | Engineer | "When AdminRoleWriteConfirmed, write ROLE characteristic (0x2A1F) with uint8 value" |

---

## Bounded Contexts

### Provisioning Context
**Responsibility:** Handles initial device role assignment with GATT ROLE write and post-write reboot handling.

#### Aggregates
- **ProvisioningRequest** — invariants: role must be valid (GW=0x01, ED=0x02, CC=0x04); networkId must be 0–65535; device must be connected; user must have engineer auth role
  - Entities: (none — single-use operation)
  - Value Objects: `DeviceRole` (uint8 mapped from display string), `NetworkId` (uint16), `DeviceName` (string)

#### Domain Services
- **ProvisioningService** — Validates form input, maps role string to uint8 value, orchestrates GATT write to ROLE characteristic, handles post-write disconnect/reboot navigation

#### Repository Interfaces
- (none — provisioning is a write-only GATT operation, no persistence)

#### Domain Events (owned by this context)
- **RoleWriteConfirmed** — fields: deviceId, roleValue (uint8), networkId (uint16)
- **RoleWritten** — fields: deviceId
- **RoleWriteFailed** — fields: deviceId, error (String)
- **DeviceRebootedAfterProvision** — fields: deviceId

---

### HA Monitoring Context
**Responsibility:** Subscribes to HA heartbeat notifications, parses 21-byte binary payload, and displays HA cluster state.

#### Aggregates
- **HaHeartbeat** — invariants: payload must be exactly 21 bytes; parsed fields must be within valid ranges
  - Entities: (none — read-only stream)
  - Value Objects: `HaRole` (active=0x01 / standby=0x02), `HaEpoch` (uint32), `HeartbeatCount` (uint32), `FailoverEvent` (timestamp + reason)

#### Domain Services
- **HaHeartbeatCodec** — Parses 21-byte HA_HB notification payload into structured HaHeartbeat value object (follows existing `QosStatus.fromBytes()` pattern in `gatt_structs.dart`)

#### Repository Interfaces
- (none — real-time stream display only)

#### Domain Events (owned by this context)
- **HaHeartbeatReceived** — fields: haRole (uint8), epoch (uint32), heartbeatCount (uint32), peerStatus (uint8), lastFailoverTimestamp (uint32), lastFailoverReason (uint8)

---

### Admin Operations Context
**Responsibility:** Engineer-only device administration: ENG_UNLOCK authentication, CMD reboot, MODE/ROLE configuration writes.

#### Aggregates
- **EngUnlockSession** — invariants: PIN must be 8 ASCII characters; write target is ENG_UNLOCK characteristic (6f8a9c11); on success, AuthSession must be elevated to engineer; on failure, must report error
  - Entities: (none)
  - Value Objects: `EngPin` (8-char ASCII string, encoded as `List<int>` via `codeUnits`)

- **DeviceCommand** — invariants: CMD writes require engineer auth; reboot (0x01) requires confirmation dialog; device must be connected
  - Entities: (none)
  - Value Objects: `CmdCode` (uint8, reboot=0x01)

- **DeviceConfig** — invariants: MODE/ROLE writes require engineer auth; ROLE write triggers device reboot; values must be valid uint8
  - Entities: (none)
  - Value Objects: `DeviceMode` (uint8), `DeviceRole` (uint8: GW=0x01, ED=0x02, CC=0x04)

#### Domain Services
- **EngUnlockService** — Shows PIN dialog, encodes PIN as ASCII bytes, writes ENG_UNLOCK characteristic, interprets firmware response (success/failure), elevates AuthSession on success
- **CmdService** — Validates engineer auth, shows confirmation dialog, writes CMD characteristic with command byte
- **ConfigWriteService** — Reads current MODE/ROLE, shows dropdown selector, writes new value with confirmation

#### Repository Interfaces
- (none — all operations are GATT writes, no local persistence)

#### Domain Events (owned by this context)
- **EngUnlockSucceeded** — fields: deviceId
- **EngUnlockFailed** — fields: deviceId, errorMessage (String)
- **CmdRebootConfirmed** — fields: deviceId, cmdCode (0x01)
- **ModeWritten** — fields: deviceId, newMode (uint8)
- **AdminRoleWriteConfirmed** — fields: deviceId, newRole (uint8)

---

### Auth Context (existing — extended)
**Responsibility:** Manages three-tier auth roles (normal → maintenance → engineer) with idle/absolute timeouts.

#### Aggregates (existing)
- **AuthSession** — invariants: engineer role requires firmware ENG_UNLOCK; idle timeout 5 min / absolute 4 hr for engineer; elevated role auto-demotes on timeout
  - Entities: (none)
  - Value Objects: `AuthRole` (enum: normal, maintenance, engineer)

#### Domain Events (relevant to this feature)
- **EngUnlockSucceeded** → triggers `AuthSession.elevate(AuthRole.engineer)`
- **AuthSessionExpired** → triggers UI demotion feedback

---

## Context Map

| From | To | Relationship | Notes |
|------|----|-------------|-------|
| Provisioning | GATT Protocol (existing) | Conformist | Uses `BleGatt.write()` and `GattUuids.role` directly |
| Provisioning | Auth (existing) | ACL | Checks `PermissionGuard.canWrite(role, GattAction.role)` before write |
| HA Monitoring | GATT Protocol (existing) | Conformist | Uses `BleGatt.subscribe()` with new `GattUuids.haHb` UUID |
| HA Monitoring | GATT Structs (existing) | Shared Kernel | New `HaHeartbeat.fromBytes()` follows same codec pattern as `QosStatus` |
| Admin Operations | GATT Protocol (existing) | Conformist | Uses `BleGatt.write()` for ENG_UNLOCK, CMD, MODE, ROLE |
| Admin Operations | Auth (existing) | ACL | Checks `PermissionGuard.canWrite()` before each operation; elevates `AuthSession` on ENG_UNLOCK success |
| Admin Operations | Provisioning | Shared Kernel | Both contexts share `DeviceRole` value object and ROLE characteristic |

---

## Ubiquitous Language Glossary

| Term | Definition | Context | Code Name |
|------|-----------|---------|-----------|
| ROLE | The operational role assigned to a BLE QoS device (Gateway, End Device, or Central Controller) | Provisioning / Admin | `GattUuids.role` (characteristic), `DeviceRole` (value object) |
| Provisioning | The process of assigning a role and network ID to an unprovisioned device | Provisioning | `ProvisioningScreen` (widget) |
| ROLE Write | Writing a uint8 role value to the ROLE GATT characteristic, triggering device reboot | Provisioning / Admin | `GattAction.role` (permission enum) |
| HA Heartbeat | A 21-byte binary payload sent via BLE notification from the HA_HB characteristic containing cluster state | HA Monitoring | `HaHeartbeat` (value object), `GattUuids.haHb` (UUID) |
| HA Role | Whether a device is the active primary or standby secondary in an HA pair | HA Monitoring | `HaRole` (value object: active=0x01, standby=0x02) |
| Epoch | The HA cluster generation counter, incremented on each failover | HA Monitoring | `HaEpoch` (value object, uint32) |
| Failover Event | A record of when and why the HA cluster switched active/standby roles | HA Monitoring | `FailoverEvent` (value object) |
| ENG_UNLOCK | The firmware authentication gate requiring an 8-character ASCII PIN to enable engineer operations | Admin Operations | `GattUuids.engUnlock` (characteristic), `GattAction.engUnlock` (permission) |
| Engineer PIN | An 8-character ASCII string written to the ENG_UNLOCK characteristic for firmware authentication | Admin Operations | `EngPin` (value object) |
| CMD | A command characteristic accepting uint8 opcodes (e.g. 0x01 = reboot) | Admin Operations | `GattUuids.cmd` (characteristic), `CmdCode` (value object) |
| MODE | The operational mode of a device, written as uint8 to the MODE characteristic | Admin Operations | `GattUuids.mode` (characteristic), `GattAction.mode` (permission) |
| AuthRole | The current authentication level of the app user (normal / maintenance / engineer) | Auth | `AuthRole` (enum in `auth_session.dart`) |
| PermissionGuard | The static permission matrix that checks AuthRole against GattAction for read/write authorization | Auth | `PermissionGuard` (class in `permission_guard.dart`) |
| BleGatt | The thin GATT operation wrapper providing read/write/subscribe over a connected BLE device | GATT Protocol | `BleGatt` (class in `ble_gatt.dart`) |
| Confirmation Dialog | A UI dialog requiring explicit user confirmation before destructive GATT writes (reboot, role change) | All write contexts | `showDialog<bool>()` pattern |

---

## Implementation Notes

### Missing GATT UUID
The HA_HB characteristic UUID `6f8a9c15-2c1a-4b6f-8a11-8ddc1f4e7b25` is not yet defined in `GattUuids`. It must be added as `static const haHb`.

### New GATT Struct Required
`HaHeartbeat` (21 bytes) codec must be added to `gatt_structs.dart` following the existing `fromBytes()` factory pattern.

### Role Value Mapping
Provisioning and Admin contexts share the same role encoding:
- `0x01` = Gateway
- `0x02` = End Device
- `0x04` = Central Controller
- `0x00` = Unprovisioned

This mapping currently exists implicitly in `ManufacturerData` constants (`roleGateway`, `roleEndDevice`) and should be reused.

### Auth Flow Dependency
Admin operations (CMD reboot, MODE/ROLE write) require `AuthRole.engineer`. The ENG_UNLOCK flow must succeed first to elevate the session. The UI should gate these operations behind an engineer auth check and prompt for ENG_UNLOCK if not authenticated.
