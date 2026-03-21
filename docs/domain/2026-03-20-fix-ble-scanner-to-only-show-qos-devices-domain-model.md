# Domain Model: Fix BLE Scanner to Only Show QoS Devices
**Date:** 2026-03-20
**Task:** Fix BLE scanner to only show QoS devices (GW and ED). Two changes: (A1) Add withServices UUID filter to BLE scanner with UUID 0x1820. (A2) Fix manufacturer_data.dart role values to match firmware adv_mfg.h — swap roleEndDevice and roleGateway constants.

---

## Event Storming

### Domain Events
| Event | Command | Actor | Policy |
|-------|---------|-------|--------|
| ScanStarted | StartScan | User (via ScannerScreen) | "When ScanStarted, apply QoS Service UUID filter (0x1820) to restrict results to QoS devices only" |
| AdvertisementReceived | — (BLE stack callback) | BLE Radio | "When AdvertisementReceived, parse ManufacturerData and apply EMA smoothing" |
| DeviceDiscovered | — (filtered by BLE stack) | BleScanner | "When DeviceDiscovered, add to device list with parsed role from ManufacturerData" |
| DeviceRoleIdentified | — (from ManufacturerData parse) | BleScanner | "When DeviceRoleIdentified, label device as Gateway (0x01) or EndDevice (0x02) per firmware constants" |
| ScanStopped | StopScan | User / DutyCycleTimer | — |

---

## Bounded Contexts

### BLE Discovery Context
**Responsibility:** Discover, filter, and present nearby BLE QoS devices to the user.

#### Aggregates
- **BleScanner** — invariants: only QoS devices (advertising service UUID 0x1820) appear in scan results; RSSI is EMA-smoothed; device status reflects staleness thresholds (online < 10s, stale 10–30s, offline > 30s)
  - Entities: `ScannedDevice` (identity: BLE remoteId)
  - Value Objects: `DeviceStatus`, `ManufacturerData`, `smoothedRssi`

#### Domain Services
- **ManufacturerData.parse()** — stateless parser that decodes raw BLE manufacturer data bytes into a structured `ManufacturerData` value object with protocol version, role, network ID, and optional GW-specific fields

#### Repository Interfaces
- None (in-memory only — scan results are transient, not persisted)

#### Domain Events (owned by this context)
- **ScanStarted** — fields: `dutyCycle: bool`
- **AdvertisementReceived** — fields: `deviceId, name, rssi, manufacturerData`
- **DeviceDiscovered** — fields: `ScannedDevice` (id, name, rssi, smoothedRssi, status, mfgData)

---

### GATT Protocol Context
**Responsibility:** Define the QoS GATT service structure (UUIDs, characteristics) and binary codecs for firmware communication.

#### Aggregates
- None (this context is purely definitional — no mutable state)

#### Domain Services
- **GattUuids** — canonical registry of all GATT UUID constants matching firmware `qos_service.h`. Source of truth for the QoS Service UUID (`0x1820` = `serviceQos`) used by the scanner filter.

#### Repository Interfaces
- None

#### Domain Events (owned by this context)
- None (constants only)

---

## Context Map

| From | To | Relationship | Notes |
|------|----|-------------|-------|
| BLE Discovery | GATT Protocol | Shared Kernel | BLE Discovery uses `GattUuids.serviceQos` from GATT Protocol as the scan filter UUID. Shared constant, no translation needed. |
| BLE Discovery | Firmware (external) | ACL | `ManufacturerData` translates raw firmware advertising bytes (adv_mfg.h format) into app-domain value objects. Role constants must match firmware: `ADV_MFG_ROLE_GW=0x01`, `ADV_MFG_ROLE_ED=0x02`. |

---

## Ubiquitous Language Glossary

| Term | Definition | Context | Code Name |
|------|-----------|---------|-----------|
| QoS Service UUID | The BLE GATT service UUID (0x1820) that identifies a device as a QoS network member | GATT Protocol | `GattUuids.serviceQos` |
| withServices filter | FlutterBluePlus scan parameter that restricts BLE scan results to devices advertising specific service UUIDs | BLE Discovery | `withServices` parameter in `FlutterBluePlus.startScan()` |
| ManufacturerData | Parsed BLE advertising manufacturer-specific data containing device role, protocol version, and network ID | BLE Discovery | `ManufacturerData` (Value Object) |
| Role | The function a device serves in the QoS network (Gateway, End Device, Central Controller, or Unprovisioned) | BLE Discovery | `ManufacturerData.role` (field), `roleGateway`, `roleEndDevice` (constants) |
| Gateway (GW) | A QoS network device that coordinates End Devices; firmware role value 0x01 (`ADV_MFG_ROLE_GW`) | BLE Discovery | `ManufacturerData.roleGateway` = `0x01` |
| End Device (ED) | A QoS network leaf device managed by a Gateway; firmware role value 0x02 (`ADV_MFG_ROLE_ED`) | BLE Discovery | `ManufacturerData.roleEndDevice` = `0x02` |
| ScannedDevice | A discovered BLE device with identity, signal strength, status, and parsed manufacturer data | BLE Discovery | `ScannedDevice` (Entity) |
| DeviceStatus | The connectivity freshness of a scanned device: online, stale, or offline based on time since last advertisement | BLE Discovery | `DeviceStatus` (enum) |
| EMA RSSI | Exponentially weighted moving average of received signal strength, used for smooth signal display | BLE Discovery | `emaRssi()`, `ScannedDevice.smoothedRssi` |
| BleScanner | The scanning engine that discovers BLE devices with duty-cycle support and EMA smoothing | BLE Discovery | `BleScanner` (class / Aggregate Root) |
| Duty Cycle | Scan pattern alternating between active scanning (2s) and pause (3s) to conserve battery | BLE Discovery | `BleScanner.scanWindow`, `BleScanner.pauseWindow` |
