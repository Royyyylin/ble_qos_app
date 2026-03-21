# Domain Model: Device Screen BLE Connection + GATT Integration
**Date:** 2026-03-21
**Task:** Device Screen BLE connection + GATT integration: (1) Call connector.connect() from scanner _onDeviceTap before navigation, await handshake + service discovery, (2) Add connection state indicator in DeviceScreen AppBar (connecting/connected/error with retry), (3) Handle connection failures gracefully with error screen and retry button, (4) Fix BLE notification subscription leak — call cancelWhenDisconnected() before setNotifyValue in ble_gatt.dart subscribe(), (5) Add disconnection detection with auto-reconnect using exponential backoff

---

## Event Storming

### Domain Events
| Event | Command | Actor | Policy |
|-------|---------|-------|--------|
| DeviceTapped | TapDevice | User | "When DeviceTapped, initiate ConnectToDevice" |
| ConnectionRequested | ConnectToDevice | ScannerScreen | "When ConnectionRequested, perform BLE connect + handshake before navigating" |
| ConnectionEstablished | — | BleConnector | "When ConnectionEstablished, navigate to DeviceScreen" |
| ConnectionFailed | — | BleConnector | "When ConnectionFailed, show error with retry option; do NOT navigate" |
| HandshakeCompleted | PerformHandshake | BleConnector | "When HandshakeCompleted, transition state to connected" |
| HandshakeFailed | — | BleConnector | "When HandshakeFailed, disconnect and surface error" |
| ConnectionStateChanged | — | BleConnector | "When ConnectionStateChanged, update AppBar indicator in DeviceScreen" |
| NotificationSubscribed | SubscribeCharacteristic | BleGatt | "When NotificationSubscribed, register cancelWhenDisconnected guard" |
| NotificationLeakPrevented | CancelWhenDisconnected | BleGatt | — |
| UnexpectedDisconnectionDetected | — | FlutterBluePlus | "When UnexpectedDisconnectionDetected, start auto-reconnect with exponential backoff" |
| ReconnectAttempted | AttemptReconnect | BleReconnect | "When ReconnectAttempted and failed, double backoff delay up to max; when succeeded, emit ConnectionEstablished" |
| ReconnectSucceeded | — | BleReconnect | "When ReconnectSucceeded, resume GATT subscriptions" |
| ReconnectExhausted | — | BleReconnect | "When ReconnectExhausted (max attempts reached), show error screen with manual retry" |
| RetryRequested | RetryConnection | User | "When RetryRequested, reset backoff and initiate ConnectToDevice" |

---

## Bounded Contexts

### BLE Connection Lifecycle
**Responsibility:** Manage the full lifecycle of a BLE connection from tap-to-connect through handshake, steady-state, disconnection detection, and auto-reconnect.

#### Aggregates
- **BleConnector** (existing, enhanced) — invariants: only one active connection at a time; must complete handshake (PeerRole write) before transitioning to `connected`; must await service discovery before GATT operations
  - Entities: none (stateful service pattern — connection is transient, not persisted)
  - Value Objects: `BleConnectionState` (disconnected | connecting | handshaking | connected), `DeviceId` (String wrapper)

- **BleReconnect** (existing, enhanced) — invariants: exponential backoff doubles each attempt (base 1s, cap 32s); max attempts configurable (default 5); cancel on explicit user disconnect; reset on successful reconnect
  - Entities: none
  - Value Objects: `BackoffConfig` (baseDelay, maxDelay, maxAttempts)

#### Domain Services
- **ConnectionOrchestrator** (new logic in `_onDeviceTap`) — coordinates the connect → handshake → navigate sequence; catches failures and prevents navigation on error

#### Repository Interfaces
- None (connections are transient, not persisted)

#### Domain Events (owned by this context)
- **ConnectionRequested** — fields: deviceId, deviceName
- **ConnectionEstablished** — fields: deviceId, services (discovered)
- **ConnectionFailed** — fields: deviceId, error, attemptNumber
- **HandshakeCompleted** — fields: deviceId
- **UnexpectedDisconnectionDetected** — fields: deviceId, reason
- **ReconnectAttempted** — fields: deviceId, attemptNumber, nextDelayMs
- **ReconnectSucceeded** — fields: deviceId, totalAttempts
- **ReconnectExhausted** — fields: deviceId, totalAttempts

---

### GATT Subscription Management
**Responsibility:** Ensure GATT notification/indication subscriptions are leak-free by guarding every subscription with cancelWhenDisconnected.

#### Aggregates
- **BleGatt** (existing, patched) — invariants: every `setNotifyValue(true)` MUST be preceded by `cancelWhenDisconnected()` on the characteristic; subscription stream must complete on disconnect
  - Entities: none
  - Value Objects: `CharacteristicUuid` (String from GattUuids)

#### Domain Services
- None (logic is internal to BleGatt.subscribe)

#### Repository Interfaces
- None

#### Domain Events (owned by this context)
- **NotificationSubscribed** — fields: charUuid, deviceId
- **NotificationLeakPrevented** — fields: charUuid, deviceId

---

### Connection State UI
**Responsibility:** Present connection state to the user in DeviceScreen AppBar and handle error/retry UX flows.

#### Aggregates
- **ConnectionStateIndicator** (new widget) — invariants: must reflect real-time BleConnectionState; must show spinner for connecting/handshaking, checkmark for connected, error icon for disconnected/failed
  - Entities: none
  - Value Objects: `BleConnectionState` (shared from BLE Connection Lifecycle context)

- **ConnectionErrorScreen** (new widget) — invariants: must show error message and retry button; retry resets backoff and re-initiates connection
  - Entities: none
  - Value Objects: `ConnectionError` (message, isRetryable)

#### Domain Services
- None (UI-only; watches provider streams)

#### Repository Interfaces
- None

#### Domain Events (owned by this context)
- **RetryRequested** — fields: deviceId

---

## Context Map

| From | To | Relationship | Notes |
|------|----|-------------|-------|
| BLE Connection Lifecycle | GATT Subscription Management | Shared Kernel | Both share `BleConnector` instance and `BleConnectionState` enum from `ble_models.dart` |
| BLE Connection Lifecycle | Connection State UI | Published Language | UI watches `BleConnector.state` stream (`StreamProvider<BleConnectionState>`) — no translation needed |
| Connection State UI | BLE Connection Lifecycle | ACL (upstream command) | UI issues `RetryRequested` which translates to `ConnectToDevice` command on `BleConnector` |
| BLE Connection Lifecycle | Navigation (existing) | Published Language | Navigation only occurs after `ConnectionEstablished`; `connectedDeviceProvider` is the shared contract |
| GATT Subscription Management | Telemetry (existing) | Shared Kernel | `statusStreamProvider` / `metricsStreamProvider` consume streams from `BleGatt.subscribe()` — leak fix is transparent |

---

## Ubiquitous Language Glossary

| Term | Definition | Context | Code Name |
|------|-----------|---------|-----------|
| BleConnectionState | Enum representing the four phases of a BLE connection: disconnected, connecting, handshaking, connected | BLE Connection Lifecycle | `BleConnectionState` (enum in `ble_models.dart`) |
| Handshake | The PeerRole write (0x02=phone) performed after BLE link establishment and service discovery to identify the phone to the device | BLE Connection Lifecycle | `_performHandshake()` in `BleConnector` |
| Service Discovery | The BLE GATT service enumeration step that occurs after physical connection, revealing available characteristics | BLE Connection Lifecycle | `discoverServices()` in `BleConnector.connect()` |
| ConnectedDevice | State object holding the id, name, and ConnectionMode of the currently connected device | BLE Connection Lifecycle | `ConnectedDevice` (class in `device_provider.dart`) |
| ConnectionMode | Whether the phone is connected to a Gateway (aggregate view) or directly to an End Device | BLE Connection Lifecycle | `ConnectionMode` (enum in `connection_mode.dart`) |
| Exponential Backoff | Reconnection retry strategy where delay doubles each attempt (1s → 2s → 4s → ... → 32s cap) up to max attempts | BLE Connection Lifecycle | `BleReconnect` (class in `ble_reconnect.dart`) |
| cancelWhenDisconnected | FlutterBluePlus API call that auto-cancels a GATT notification subscription when the device disconnects, preventing resource leaks | GATT Subscription Management | `cancelWhenDisconnected()` on `BluetoothCharacteristic` |
| NotificationLeak | Bug where GATT notification listeners persist after disconnect, causing stale callbacks and potential memory leaks | GATT Subscription Management | (defect — no code name; fix is adding `cancelWhenDisconnected()` call) |
| ConnectionStateIndicator | AppBar widget showing real-time connection status via icon + color (spinner/check/error) | Connection State UI | `ConnectionStateIndicator` (new widget) |
| ConnectionErrorScreen | Full-screen error state shown when connection fails or reconnect is exhausted, with retry button | Connection State UI | `ConnectionErrorScreen` (new widget) |
| DeviceTap | User gesture on a ScanDeviceTile in ScannerScreen that initiates the connect-then-navigate flow | Connection State UI | `_onDeviceTap()` in `ScannerScreen` |
| BleConnector | Infrastructure adapter managing BLE connection lifecycle including connect, handshake, disconnect, and state broadcasting | BLE Connection Lifecycle | `BleConnector` (class in `ble_connector.dart`) |
| BleGatt | Thin GATT operation wrapper providing read/write/subscribe over a connected BLE link | GATT Subscription Management | `BleGatt` (class in `ble_gatt.dart`) |
| BleReconnect | Auto-reconnect handler using exponential backoff for unexpected disconnections | BLE Connection Lifecycle | `BleReconnect` (class in `ble_reconnect.dart`) |
| bleConnectorProvider | Riverpod provider exposing the singleton BleConnector instance | BLE Connection Lifecycle | `bleConnectorProvider` (in `ble_connector.dart`) |
| connectedDeviceProvider | Riverpod StateNotifierProvider holding the currently connected device state | BLE Connection Lifecycle | `connectedDeviceProvider` (in `device_provider.dart`) |
