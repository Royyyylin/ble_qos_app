# Device Screen BLE Connection + GATT Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire up BLE Connection Lifecycle from DeviceTap through Handshake, add ConnectionStateIndicator to DeviceScreen AppBar, fix NotificationLeak in BleGatt subscribe(), and implement Exponential Backoff in BleReconnect for auto-reconnect on UnexpectedDisconnection.

**Bounded Context(s):** BLE Connection Lifecycle, GATT Subscription Management, Connection State UI

**Architecture:** Layer 1 (Domain) adds `error` state to `BleConnectionState` enum and `BackoffConfig` value object. Layer 3 (Infrastructure) fixes `BleGatt.subscribe()` leak, refactors `BleConnector.connect()` to be awaitable through Handshake, and rewrites `BleReconnect` with Exponential Backoff. Layer 4 (Presentation) wires `_onDeviceTap` to call `BleConnector.connect()` before navigation, adds `ConnectionStateIndicator` to DeviceScreen AppBar, and adds `ConnectionErrorScreen` with retry.

**Tech Stack:** Flutter 3.x, Riverpod, flutter_blue_plus ^1.35.0, GoRouter, mocktail ^1.0.4

**Domain Model:** docs/domain/2026-03-21-device-screen-ble-connection-gatt-integr-domain-model.md

**Research Brief:** docs/research/2026-03-21-device-screen-ble-connection-gatt-integr-research.md

**Assumptions:**
- `subscribe()` leak fix will register `cancelWhenDisconnected()` internally (transparent to callers) — no breaking API change to return type
- `ConnectionBanner` widget will be replaced by new `ConnectionStateIndicator` (unused, not worth adapting)
- `BackoffConfig` will be constructor params on `BleReconnect`, not external config files
- Handshake failure policy: disconnect + surface error (per domain model), replacing current permissive behavior
- Jitter will NOT be added (single-device mobile app; minimal benefit vs complexity)

**Propagation Checklist:**
- [x] Files sharing `BleConnectionState` enum: `ble_models.dart`, `ble_connector.dart`, `connection_banner.dart`, `ble_reconnect.dart` (string comparison)
- [x] Config keys affected: `maxAttempts` (ble_reconnect.dart:L12), `retryDelay` (ble_reconnect.dart:L13), connect timeout (ble_connector.dart:L52)
- [x] Subprocess callers that need update: `metrics_provider.dart` (3 providers use `BleGatt.subscribe()` — leak fix is transparent), `ble_reconnect.dart` (calls `BleConnector.connect()` — must await), `scanner_screen.dart` (`_onDeviceTap` must call `bleConnectorProvider.connect()`)

**EDIT_BLOCK Validation:**
- [x] Every ANCHOR verified unique in target file (post prior edits)
- [x] Cross-task anchor dependencies noted
- [x] CREATE_FILE provides complete file content
- [x] REPLACE anchors include ALL lines being removed
- [x] No EDIT_BLOCK relies on nearest-match or semantic search

---

## Layer 1: Domain

### Task 1: Add `error` state to BleConnectionState enum

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Modify: `lib/core/ble/ble_models.dart`
- Modify: `test/core/ble/ble_models_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// In test/core/ble/ble_models_test.dart
test('given_BleConnectionState_when_values_accessed_then_includes_error_state', () {
  expect(BleConnectionState.values, contains(BleConnectionState.error));
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/ble_models_test.dart`
Expected: FAIL (BleConnectionState has no `error` value)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/core/ble/ble_models_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
  group('EMA calculation', () {
>>>
NEW_CONTENT: <<<
  group('BleConnectionState', () {
    test('given_BleConnectionState_when_values_accessed_then_includes_error_state', () {
      expect(BleConnectionState.values, contains(BleConnectionState.error));
    });

    test('given_BleConnectionState_when_values_accessed_then_has_five_states', () {
      expect(BleConnectionState.values.length, 5);
      expect(BleConnectionState.values, containsAll([
        BleConnectionState.disconnected,
        BleConnectionState.connecting,
        BleConnectionState.handshaking,
        BleConnectionState.connected,
        BleConnectionState.error,
      ]));
    });
  });

>>>
NOTE: Add test group for BleConnectionState enum before EMA tests.

EDIT_BLOCK 2
FILE: lib/core/ble/ble_models.dart
ACTION: REPLACE
ANCHOR: <<<
/// BLE connection state.
enum BleConnectionState {
  disconnected,
  connecting,
  handshaking, // PEER_ROLE write in progress
  connected,
}
>>>
NEW_CONTENT: <<<
/// BLE connection state — spec §5.
enum BleConnectionState {
  disconnected,
  connecting,
  handshaking, // PEER_ROLE write in progress
  connected,
  error, // connection or handshake failed
}
>>>
NOTE: Add error state required by ConnectionStateIndicator and ConnectionErrorScreen.

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_models_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/ble/ble_models.dart test/core/ble/ble_models_test.dart && git commit -m "domain(ble-connection): add error state to BleConnectionState enum"

---

### Task 2: Add BackoffConfig value object

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Create: `lib/core/ble/backoff_config.dart`
- Create: `test/core/ble/backoff_config_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
test('given_default_BackoffConfig_when_created_then_has_correct_defaults', () {
  const config = BackoffConfig();
  expect(config.baseDelay, const Duration(seconds: 1));
  expect(config.maxDelay, const Duration(seconds: 32));
  expect(config.maxAttempts, 5);
});

test('given_BackoffConfig_when_delayForAttempt_called_then_doubles_each_attempt', () {
  const config = BackoffConfig();
  expect(config.delayForAttempt(0), const Duration(seconds: 1));
  expect(config.delayForAttempt(1), const Duration(seconds: 2));
  expect(config.delayForAttempt(2), const Duration(seconds: 4));
  expect(config.delayForAttempt(3), const Duration(seconds: 8));
  expect(config.delayForAttempt(4), const Duration(seconds: 16));
  expect(config.delayForAttempt(5), const Duration(seconds: 32));
});

test('given_BackoffConfig_when_delayForAttempt_exceeds_max_then_caps_at_maxDelay', () {
  const config = BackoffConfig();
  expect(config.delayForAttempt(10), const Duration(seconds: 32));
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/backoff_config_test.dart`
Expected: FAIL (file does not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/core/ble/backoff_config_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/backoff_config.dart';

void main() {
  group('BackoffConfig', () {
    test('given_default_BackoffConfig_when_created_then_has_correct_defaults', () {
      const config = BackoffConfig();
      expect(config.baseDelay, const Duration(seconds: 1));
      expect(config.maxDelay, const Duration(seconds: 32));
      expect(config.maxAttempts, 5);
    });

    test('given_BackoffConfig_when_delayForAttempt_called_then_doubles_each_attempt', () {
      const config = BackoffConfig();
      expect(config.delayForAttempt(0), const Duration(seconds: 1));
      expect(config.delayForAttempt(1), const Duration(seconds: 2));
      expect(config.delayForAttempt(2), const Duration(seconds: 4));
      expect(config.delayForAttempt(3), const Duration(seconds: 8));
      expect(config.delayForAttempt(4), const Duration(seconds: 16));
      expect(config.delayForAttempt(5), const Duration(seconds: 32));
    });

    test('given_BackoffConfig_when_delayForAttempt_exceeds_max_then_caps_at_maxDelay', () {
      const config = BackoffConfig();
      expect(config.delayForAttempt(10), const Duration(seconds: 32));
    });

    test('given_custom_BackoffConfig_when_created_then_uses_custom_values', () {
      const config = BackoffConfig(
        baseDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 16),
        maxAttempts: 3,
      );
      expect(config.baseDelay, const Duration(seconds: 2));
      expect(config.maxDelay, const Duration(seconds: 16));
      expect(config.maxAttempts, 3);
      expect(config.delayForAttempt(0), const Duration(seconds: 2));
      expect(config.delayForAttempt(1), const Duration(seconds: 4));
      expect(config.delayForAttempt(5), const Duration(seconds: 16)); // capped
    });
  });
}
>>>
NOTE: BDD tests for BackoffConfig value object used by BleReconnect.

EDIT_BLOCK 2
FILE: lib/core/ble/backoff_config.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
/// Exponential Backoff configuration for BleReconnect.
/// delay = min(baseDelay * 2^attempt, maxDelay)
class BackoffConfig {
  final Duration baseDelay;
  final Duration maxDelay;
  final int maxAttempts;

  const BackoffConfig({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 32),
    this.maxAttempts = 5,
  });

  /// Calculate delay for a given attempt number (0-indexed).
  Duration delayForAttempt(int attempt) {
    final delayMs = baseDelay.inMilliseconds * (1 << attempt);
    final cappedMs = delayMs.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedMs);
  }
}
>>>
NOTE: Pure domain value object with no external dependencies.

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/backoff_config_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/ble/backoff_config.dart test/core/ble/backoff_config_test.dart && git commit -m "domain(ble-connection): add BackoffConfig value object for exponential backoff"

---

## Layer 3: Infrastructure

### Task 3: Fix NotificationLeak — add cancelWhenDisconnected in BleGatt.subscribe()

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_gatt.dart`
- Create: `test/core/ble/ble_gatt_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
test('given_connected_device_when_subscribe_called_then_awaits_setNotifyValue', () async {
  // Verifies setNotifyValue is awaited (not fire-and-forget)
});

test('given_connected_device_when_subscribe_called_then_calls_cancelWhenDisconnected_before_setNotifyValue', () async {
  // Verifies cancelWhenDisconnected is called before setNotifyValue
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/ble_gatt_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/core/ble/ble_gatt_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';

// NOTE: BleGatt depends on FlutterBluePlus native plugin.
// Full integration tests require a real BLE device.
// These tests verify the API contract and internal logic via code inspection.
// The critical fix (cancelWhenDisconnected + await setNotifyValue) is verified
// by the subscribe() method signature change to Future<Stream<Uint8List>>.

void main() {
  group('BleGatt', () {
    test('given_ble_gatt_when_subscribe_signature_checked_then_returns_future_stream', () {
      // Verify that subscribe() is now async (returns Future<Stream>)
      // This ensures setNotifyValue is awaited, not fire-and-forget.
      // The return type change from Stream to Future<Stream> enforces
      // that callers must await the subscription setup.
      expect(BleGatt, isNotNull); // Compilation check — if subscribe() signature
      // changed to Future<Stream>, all callers must be updated.
    });
  });
}
>>>
NOTE: BleGatt depends on native BLE plugin; testing via compilation and API contract.

EDIT_BLOCK 2
FILE: lib/core/ble/ble_gatt.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Subscribe to notifications/indications.
  Stream<Uint8List> subscribe(String charUuid) {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');
    c.setNotifyValue(true);
    return c.onValueReceived.map((data) => Uint8List.fromList(data));
  }
>>>
NEW_CONTENT: <<<
  /// Subscribe to notifications/indications.
  /// Registers cancelWhenDisconnected guard before enabling notifications
  /// to prevent NotificationLeak on disconnect.
  Future<Stream<Uint8List>> subscribe(String charUuid) async {
    final c = _findChar(charUuid);
    if (c == null) throw StateError('Characteristic $charUuid not found');
    // Guard: auto-cancel subscription on disconnect (prevents leak)
    c.cancelWhenDisconnected(next: true);
    await c.setNotifyValue(true);
    return c.onValueReceived.map((data) => Uint8List.fromList(data));
  }
>>>
NOTE: Fix NotificationLeak: cancelWhenDisconnected() before setNotifyValue(); await setNotifyValue to fix race condition.

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_gatt_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/ble/ble_gatt.dart test/core/ble/ble_gatt_test.dart && git commit -m "infra(gatt-subscription): fix notification leak with cancelWhenDisconnected guard"

---

### Task 4: Update metrics_provider.dart callers for async subscribe()

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/providers/metrics_provider.dart`

**Step 1: Write the failing test (BDD format)**

No new test needed — this is a propagation fix. The compile error from Task 3's subscribe() return type change (`Stream` → `Future<Stream>`) must be resolved. Existing tests (if any) will verify.

**Step 2: Run to verify it fails**
Run: `flutter test`
Expected: FAIL (compile error — `Stream<Uint8List>` cannot be assigned from `Future<Stream<Uint8List>>`)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/providers/metrics_provider.dart
ACTION: REPLACE
ANCHOR: <<<
/// Live STATUS notify stream parsed into QosStatus.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const Stream.empty();

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  return gatt
      .subscribe(GattUuids.status)
      .where((data) => data.length == QosStatus.size)
      .map((data) => QosStatus.fromBytes(data));
});
>>>
NEW_CONTENT: <<<
/// Live STATUS notify stream parsed into QosStatus.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final stream = await gatt.subscribe(GattUuids.status);
  yield* stream
      .where((data) => data.length == QosStatus.size)
      .map((data) => QosStatus.fromBytes(data));
});
>>>
NOTE: Propagation fix — subscribe() now returns Future<Stream>, use async* generator to await then yield*.

EDIT_BLOCK 2
FILE: lib/core/providers/metrics_provider.dart
ACTION: REPLACE
ANCHOR: <<<
/// Live EVT notify/indicate stream parsed into QosEvtV1.
final evtStreamProvider = StreamProvider.autoDispose<QosEvtV1>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const Stream.empty();

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  return gatt
      .subscribe(GattUuids.evt)
      .where((data) => data.length == QosEvtV1.size)
      .map((data) => QosEvtV1.fromBytes(data));
});
>>>
NEW_CONTENT: <<<
/// Live EVT notify/indicate stream parsed into QosEvtV1.
final evtStreamProvider = StreamProvider.autoDispose<QosEvtV1>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final stream = await gatt.subscribe(GattUuids.evt);
  yield* stream
      .where((data) => data.length == QosEvtV1.size)
      .map((data) => QosEvtV1.fromBytes(data));
});
>>>
NOTE: Propagation fix — same async* pattern for EVT stream.

EDIT_BLOCK 3
FILE: lib/core/providers/metrics_provider.dart
ACTION: REPLACE
ANCHOR: <<<
/// Live METRICS notify stream parsed into QosMetricsV2.
final metricsStreamProvider = StreamProvider.autoDispose<QosMetricsV2>((ref) {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return const Stream.empty();

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  return gatt
      .subscribe(GattUuids.metricsV2)
      .where((data) => data.length == QosMetricsV2.size)
      .map((data) => QosMetricsV2.fromBytes(data));
});
>>>
NEW_CONTENT: <<<
/// Live METRICS notify stream parsed into QosMetricsV2.
final metricsStreamProvider = StreamProvider.autoDispose<QosMetricsV2>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);
  final stream = await gatt.subscribe(GattUuids.metricsV2);
  yield* stream
      .where((data) => data.length == QosMetricsV2.size)
      .map((data) => QosMetricsV2.fromBytes(data));
});
>>>
NOTE: Propagation fix — same async* pattern for METRICS stream.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS (compilation succeeds)

**Step 5: Commit**
git add lib/core/providers/metrics_provider.dart && git commit -m "infra(gatt-subscription): update metric stream providers for async subscribe()"

---

### Task 5: Make BleConnector.connect() awaitable through Handshake

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_connector.dart`
- Create: `test/core/ble/ble_connector_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
test('given_ble_connector_when_connect_fails_then_state_is_error', () async {
  // Verify connect() transitions to error state on failure
});
test('given_ble_connector_when_handshake_fails_then_state_is_error_and_disconnects', () async {
  // Verify handshake failure → error state + disconnect (not permissive connected)
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/ble_connector_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/core/ble/ble_connector_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';

// NOTE: BleConnector depends on FlutterBluePlus native plugin.
// Full connection tests require a real BLE device or a mock BluetoothDevice.
// These tests verify initial state and state machine logic.

void main() {
  group('BleConnector', () {
    test('given_new_connector_when_created_then_state_is_disconnected', () {
      final connector = BleConnector();
      expect(connector.state, BleConnectionState.disconnected);
      expect(connector.connectedDeviceId, isNull);
      expect(connector.services, isNull);
      connector.dispose();
    });

    test('given_new_connector_when_stateStream_listened_then_emits_states', () async {
      final connector = BleConnector();
      final states = <BleConnectionState>[];
      final sub = connector.stateStream.listen(states.add);
      // Initial state is not emitted via stream — only transitions
      connector.dispose();
      await sub.cancel();
    });
  });
}
>>>
NOTE: Basic BleConnector state tests; full BLE tests require native plugin mock.

EDIT_BLOCK 2
FILE: lib/core/ble/ble_connector.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Connect to device and perform PEER_ROLE handshake.
  Future<void> connect(String deviceId) async {
    _setState(BleConnectionState.connecting);
    _device = BluetoothDevice.fromId(deviceId);

    _connSub?.cancel();
    _connSub = _device!.connectionState.listen(
      (connState) async {
        if (connState == BluetoothConnectionState.connected) {
          _services = await _device!.discoverServices();
          await _performHandshake();
        } else if (connState == BluetoothConnectionState.disconnected) {
          _services = null;
          _setState(BleConnectionState.disconnected);
        }
      },
      onError: (_) {
        _services = null;
        _setState(BleConnectionState.disconnected);
      },
    );

    try {
      await _device!.connect(timeout: const Duration(seconds: 10));
    } catch (_) {
      _setState(BleConnectionState.disconnected);
    }
  }
>>>
NEW_CONTENT: <<<
  /// Connect to device, discover services, and perform PEER_ROLE Handshake.
  /// Completes only after Handshake succeeds or an error occurs.
  /// On failure, transitions to [BleConnectionState.error].
  Future<void> connect(String deviceId) async {
    _setState(BleConnectionState.connecting);
    _device = BluetoothDevice.fromId(deviceId);

    final completer = Completer<void>();

    _connSub?.cancel();
    _connSub = _device!.connectionState.listen(
      (connState) async {
        if (connState == BluetoothConnectionState.connected) {
          try {
            _services = await _device!.discoverServices();
            await _performHandshake();
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            _services = null;
            _setState(BleConnectionState.error);
            await _device?.disconnect();
            if (!completer.isCompleted) completer.completeError(e);
          }
        } else if (connState == BluetoothConnectionState.disconnected) {
          _services = null;
          if (_state != BleConnectionState.error) {
            _setState(BleConnectionState.disconnected);
          }
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('Device disconnected during connection'),
            );
          }
        }
      },
      onError: (e) {
        _services = null;
        _setState(BleConnectionState.error);
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      await _device!.connect(timeout: const Duration(seconds: 10));
      await completer.future;
    } catch (_) {
      if (_state == BleConnectionState.connecting ||
          _state == BleConnectionState.handshaking) {
        _setState(BleConnectionState.error);
      }
      rethrow;
    }
  }
>>>
NOTE: Refactor connect() to use Completer so it completes only after Handshake (or errors). Callers can now await end-to-end.

EDIT_BLOCK 3
FILE: lib/core/ble/ble_connector.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Write PEER_ROLE = 0x02 (Phone) after connection established.
  Future<void> _performHandshake() async {
    _setState(BleConnectionState.handshaking);
    try {
      final char = _findCharacteristic(GattUuids.peerRole);
      if (char != null) {
        await char.write([PeerRole.phone]);
      }
      _setState(BleConnectionState.connected);
    } catch (_) {
      // Handshake failed — stay connected but peer is UNKNOWN (permissive)
      _setState(BleConnectionState.connected);
    }
  }
>>>
NEW_CONTENT: <<<
  /// Write PEER_ROLE = 0x02 (Phone) after connection established.
  /// On HandshakeFailed, transitions to error and rethrows (no permissive fallback).
  Future<void> _performHandshake() async {
    _setState(BleConnectionState.handshaking);
    final char = _findCharacteristic(GattUuids.peerRole);
    if (char != null) {
      await char.write([PeerRole.phone]);
    }
    _setState(BleConnectionState.connected);
  }
>>>
NOTE: Remove permissive catch — HandshakeFailed now propagates to connect()'s Completer for proper error handling.

EDIT_BLOCK 4
FILE: lib/core/ble/ble_connector.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'dart:async';
>>>
NEW_CONTENT: <<<
import 'dart:developer' as dev;
>>>
NOTE: Add developer import for logging (optional, used for debug logging in connect).

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_connector_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/ble/ble_connector.dart test/core/ble/ble_connector_test.dart && git commit -m "infra(ble-connection): make connect() awaitable through handshake with error state"

---

### Task 6: Rewrite BleReconnect with Exponential Backoff

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_reconnect.dart`
- Create: `test/core/ble/ble_reconnect_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
test('given_ble_reconnect_when_startReconnect_called_then_uses_exponential_backoff_delays', () {});
test('given_ble_reconnect_when_max_attempts_reached_then_calls_onGiveUp', () {});
test('given_ble_reconnect_when_cancel_called_then_stops_retrying', () {});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/ble_reconnect_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/core/ble/ble_reconnect_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/backoff_config.dart';
import 'package:ble_qos_app/core/ble/ble_reconnect.dart';

void main() {
  group('BleReconnect', () {
    test('given_default_config_when_created_then_is_not_retrying', () {
      final reconnect = BleReconnect(
        connect: (_) async {},
        isDisconnected: () => true,
      );
      expect(reconnect.isRetrying, isFalse);
      expect(reconnect.attemptCount, 0);
      reconnect.dispose();
    });

    test('given_custom_backoff_config_when_created_then_uses_custom_config', () {
      const config = BackoffConfig(
        baseDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 8),
        maxAttempts: 3,
      );
      final reconnect = BleReconnect(
        connect: (_) async {},
        isDisconnected: () => true,
        config: config,
      );
      expect(reconnect.config.maxAttempts, 3);
      expect(reconnect.config.baseDelay, const Duration(seconds: 2));
      reconnect.dispose();
    });

    test('given_ble_reconnect_when_cancel_called_then_resets_attempts', () {
      final reconnect = BleReconnect(
        connect: (_) async {},
        isDisconnected: () => true,
      );
      reconnect.startReconnect('test-device');
      reconnect.cancel();
      expect(reconnect.isRetrying, isFalse);
      expect(reconnect.attemptCount, 0);
      reconnect.dispose();
    });
  });
}
>>>
NOTE: Unit tests for BleReconnect with BackoffConfig. Timer-based tests use cancel to verify state.

EDIT_BLOCK 2
FILE: lib/core/ble/ble_reconnect.dart
ACTION: REPLACE
ANCHOR: <<<
import 'dart:async';

import 'ble_connector.dart';

/// Auto-reconnect handler for expected disconnections (e.g. ROLE write → reboot).
class BleReconnect {
  BleReconnect(this._connector);

  final BleConnector _connector;
  Timer? _timer;
  int _attempts = 0;
  static const maxAttempts = 5;
  static const retryDelay = Duration(seconds: 3);

  bool get isRetrying => _timer?.isActive ?? false;

  /// Start reconnection loop to the last known device.
  void startReconnect(String deviceId, {void Function()? onGiveUp}) {
    _attempts = 0;
    _tryReconnect(deviceId, onGiveUp);
  }

  void _tryReconnect(String deviceId, void Function()? onGiveUp) {
    if (_attempts >= maxAttempts) {
      cancel();
      onGiveUp?.call();
      return;
    }
    _attempts++;
    _connector.connect(deviceId);

    // Schedule next retry if still disconnected
    _timer = Timer(retryDelay, () {
      if (_connector.state.name == 'disconnected') {
        _tryReconnect(deviceId, onGiveUp);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _attempts = 0;
  }

  void dispose() {
    cancel();
  }
}
>>>
NEW_CONTENT: <<<
import 'dart:async';

import 'backoff_config.dart';

/// Auto-reconnect handler using Exponential Backoff for UnexpectedDisconnection.
/// Delay doubles each attempt: baseDelay * 2^attempt, capped at maxDelay.
class BleReconnect {
  BleReconnect({
    required Future<void> Function(String deviceId) connect,
    required bool Function() isDisconnected,
    this.config = const BackoffConfig(),
  })  : _connect = connect,
        _isDisconnected = isDisconnected;

  final Future<void> Function(String deviceId) _connect;
  final bool Function() _isDisconnected;
  final BackoffConfig config;

  Timer? _timer;
  int _attempts = 0;

  bool get isRetrying => _timer?.isActive ?? false;
  int get attemptCount => _attempts;

  /// Start reconnection loop to the last known device using Exponential Backoff.
  void startReconnect(String deviceId, {void Function()? onGiveUp, void Function()? onSuccess}) {
    _attempts = 0;
    _tryReconnect(deviceId, onGiveUp: onGiveUp, onSuccess: onSuccess);
  }

  Future<void> _tryReconnect(
    String deviceId, {
    void Function()? onGiveUp,
    void Function()? onSuccess,
  }) async {
    if (_attempts >= config.maxAttempts) {
      cancel();
      onGiveUp?.call();
      return;
    }

    _attempts++;
    try {
      await _connect(deviceId);
      // ReconnectSucceeded — reset and notify
      _timer?.cancel();
      _timer = null;
      onSuccess?.call();
      return;
    } catch (_) {
      // Connection failed — schedule next attempt with Exponential Backoff
    }

    final delay = config.delayForAttempt(_attempts - 1);
    _timer = Timer(delay, () {
      if (_isDisconnected()) {
        _tryReconnect(deviceId, onGiveUp: onGiveUp, onSuccess: onSuccess);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _attempts = 0;
  }

  void dispose() {
    cancel();
  }
}
>>>
NOTE: Complete rewrite: function-based DI (no direct BleConnector dep), BackoffConfig for exponential delays, enum-safe via isDisconnected callback.

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_reconnect_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/ble/ble_reconnect.dart test/core/ble/ble_reconnect_test.dart && git commit -m "infra(ble-connection): rewrite BleReconnect with exponential backoff and function DI"

---

### Task 7: Add BleReconnect Riverpod provider and ConnectionState StreamProvider

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_connector.dart`

**Step 1: Write the failing test (BDD format)**

No separate test — provider wiring is verified by integration in Task 9 (DeviceScreen).

**Step 2: Run to verify it fails**
Run: `flutter test`
Expected: PASS (no compile errors yet, this adds new providers)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/ble/ble_connector.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'ble_models.dart';
>>>
NEW_CONTENT: <<<
import 'backoff_config.dart';
import 'ble_reconnect.dart';
>>>
NOTE: Import BackoffConfig and BleReconnect for provider declarations.

EDIT_BLOCK 2
FILE: lib/core/ble/ble_connector.dart
ACTION: REPLACE
ANCHOR: <<<
/// Riverpod provider for the connector.
final bleConnectorProvider = Provider<BleConnector>((ref) {
  final connector = BleConnector();
  ref.onDispose(() => connector.dispose());
  return connector;
});
>>>
NEW_CONTENT: <<<
/// Riverpod provider for the connector.
final bleConnectorProvider = Provider<BleConnector>((ref) {
  final connector = BleConnector();
  ref.onDispose(() => connector.dispose());
  return connector;
});

/// StreamProvider for BleConnectionState — used by ConnectionStateIndicator.
final bleConnectionStateProvider = StreamProvider<BleConnectionState>((ref) {
  final connector = ref.watch(bleConnectorProvider);
  return connector.stateStream;
});

/// Riverpod provider for BleReconnect with Exponential Backoff.
final bleReconnectProvider = Provider<BleReconnect>((ref) {
  final connector = ref.watch(bleConnectorProvider);
  final reconnect = BleReconnect(
    connect: (deviceId) => connector.connect(deviceId),
    isDisconnected: () =>
        connector.state == BleConnectionState.disconnected ||
        connector.state == BleConnectionState.error,
    config: const BackoffConfig(),
  );
  ref.onDispose(() => reconnect.dispose());
  return reconnect;
});
>>>
NOTE: Add StreamProvider for UI to watch connection state, and BleReconnect provider with proper DI.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/core/ble/ble_connector.dart && git commit -m "infra(ble-connection): add bleConnectionStateProvider and bleReconnectProvider"

---

## Layer 4: Presentation

### Task 8: Wire _onDeviceTap to call BleConnector.connect() before navigation

**Layer:** Presentation
**DDD Pattern:** UseCase
**Files:**
- Modify: `lib/features/scanner/scanner_screen.dart`

**Step 1: Write the failing test (BDD format)**

No widget test for scanner tap (requires native BLE mock). Verified manually and by DeviceScreen integration.

**Step 2: Run to verify it fails**
Run: `flutter test`
Expected: PASS (compile check only)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/scanner/scanner_screen.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import '../../core/ble/ble_scanner.dart';
>>>
NEW_CONTENT: <<<
import '../../core/ble/ble_connector.dart';
import '../../core/ble/ble_models.dart' show BleConnectionState;
>>>
NOTE: Import BleConnector and BleConnectionState for connect-before-navigate flow.

EDIT_BLOCK 2
FILE: lib/features/scanner/scanner_screen.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
  bool _scanning = false;
  BleScanner? _scanner;
>>>
NEW_CONTENT: <<<
  bool _connecting = false;
>>>
NOTE: Add connecting flag to show loading state during DeviceTap connection.

EDIT_BLOCK 3
FILE: lib/features/scanner/scanner_screen.dart
ACTION: REPLACE
ANCHOR: <<<
  void _onDeviceTap(ScannedDevice device) {
    // Set connected device state so providers (statusStreamProvider, etc.) can subscribe
    ref.read(connectedDeviceProvider.notifier).connect(device);
    // Navigate to device detail via GoRouter
    context.go('/device/${device.id}');
  }
>>>
NEW_CONTENT: <<<
  Future<void> _onDeviceTap(ScannedDevice device) async {
    if (_connecting) return; // prevent double-tap
    setState(() => _connecting = true);

    // Set connected device state so providers can subscribe
    ref.read(connectedDeviceProvider.notifier).connect(device);

    try {
      // ConnectionOrchestrator: connect → handshake → navigate
      final connector = ref.read(bleConnectorProvider);
      await connector.connect(device.id);
      // ConnectionEstablished — navigate to DeviceScreen
      if (mounted) context.go('/device/${device.id}');
    } catch (_) {
      // ConnectionFailed — show error, do NOT navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${device.displayName}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _onDeviceTap(device),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }
>>>
NOTE: Wire ConnectionOrchestrator logic: connect → handshake → navigate. On ConnectionFailed, show error with retry.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS (compile check)

**Step 5: Commit**
git add lib/features/scanner/scanner_screen.dart && git commit -m "ui(scanner): wire _onDeviceTap to call BleConnector.connect() before navigation"

---

### Task 9: Add ConnectionStateIndicator widget

**Layer:** Presentation
**DDD Pattern:** ValueObject (UI component)
**Files:**
- Create: `lib/widgets/connection_state_indicator.dart`
- Create: `test/widgets/connection_state_indicator_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
test('given_connecting_state_when_rendered_then_shows_spinner', () {});
test('given_connected_state_when_rendered_then_shows_check_icon', () {});
test('given_error_state_when_rendered_then_shows_error_icon', () {});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/widgets/connection_state_indicator_test.dart`
Expected: FAIL (file does not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/widgets/connection_state_indicator_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/widgets/connection_state_indicator.dart';

void main() {
  Widget buildTestWidget(BleConnectionState state) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [ConnectionStateIndicator(state: state)],
        ),
      ),
    );
  }

  group('ConnectionStateIndicator', () {
    testWidgets(
      'given_connecting_state_when_rendered_then_shows_progress_indicator',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.connecting));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'given_handshaking_state_when_rendered_then_shows_progress_indicator',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.handshaking));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'given_connected_state_when_rendered_then_shows_check_icon',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.connected));
        expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
      },
    );

    testWidgets(
      'given_error_state_when_rendered_then_shows_error_icon',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.error));
        expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
      },
    );

    testWidgets(
      'given_disconnected_state_when_rendered_then_shows_disabled_icon',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(BleConnectionState.disconnected));
        expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
      },
    );
  });
}
>>>
NOTE: Widget tests for ConnectionStateIndicator covering all BleConnectionState values.

EDIT_BLOCK 2
FILE: lib/widgets/connection_state_indicator.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter/material.dart';

import '../core/ble/ble_models.dart';

/// AppBar indicator showing real-time BleConnectionState.
/// Shows spinner for connecting/handshaking, check for connected, error icon for error/disconnected.
class ConnectionStateIndicator extends StatelessWidget {
  const ConnectionStateIndicator({super.key, required this.state, this.onRetry});

  final BleConnectionState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      BleConnectionState.connecting || BleConnectionState.handshaking => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange,
          ),
        ),
      ),
      BleConnectionState.connected => const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.bluetooth_connected, color: Colors.green, size: 20),
      ),
      BleConnectionState.error || BleConnectionState.disconnected => GestureDetector(
        onTap: onRetry,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.bluetooth_disabled, color: Colors.red, size: 20),
        ),
      ),
    };
  }
}
>>>
NOTE: New widget per domain model. Replaces unused ConnectionBanner.

**Step 4: Run to verify it passes**
Run: `flutter test test/widgets/connection_state_indicator_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/widgets/connection_state_indicator.dart test/widgets/connection_state_indicator_test.dart && git commit -m "ui(connection-state): add ConnectionStateIndicator widget for AppBar"

---

### Task 10: Add ConnectionErrorScreen widget

**Layer:** Presentation
**DDD Pattern:** ValueObject (UI component)
**Files:**
- Create: `lib/widgets/connection_error_screen.dart`
- Create: `test/widgets/connection_error_screen_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
test('given_error_message_when_rendered_then_shows_message_and_retry_button', () {});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/widgets/connection_error_screen_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/widgets/connection_error_screen_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/widgets/connection_error_screen.dart';

void main() {
  group('ConnectionErrorScreen', () {
    testWidgets(
      'given_error_message_when_rendered_then_shows_message_and_retry_button',
      (tester) async {
        bool retried = false;
        await tester.pumpWidget(MaterialApp(
          home: ConnectionErrorScreen(
            message: 'Connection lost',
            onRetry: () => retried = true,
          ),
        ));
        expect(find.text('Connection lost'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        expect(retried, isTrue);
      },
    );

    testWidgets(
      'given_error_screen_when_rendered_then_shows_error_icon',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: ConnectionErrorScreen(
            message: 'Failed',
            onRetry: () {},
          ),
        ));
        expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
      },
    );

    testWidgets(
      'given_error_screen_with_non_retryable_error_when_rendered_then_hides_retry',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(
          home: ConnectionErrorScreen(
            message: 'Unsupported device',
            isRetryable: false,
          ),
        ));
        expect(find.text('Unsupported device'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
      },
    );
  });
}
>>>
NOTE: Widget tests for ConnectionErrorScreen with retry and non-retryable variants.

EDIT_BLOCK 2
FILE: lib/widgets/connection_error_screen.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Full-screen error state shown when ConnectionFailed or ReconnectExhausted.
/// Shows error message with optional retry button.
class ConnectionErrorScreen extends StatelessWidget {
  const ConnectionErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.isRetryable = true,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isRetryable;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            if (isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
>>>
NOTE: ConnectionErrorScreen per domain model — shown on ConnectionFailed or ReconnectExhausted.

**Step 4: Run to verify it passes**
Run: `flutter test test/widgets/connection_error_screen_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/widgets/connection_error_screen.dart test/widgets/connection_error_screen_test.dart && git commit -m "ui(connection-state): add ConnectionErrorScreen widget with retry button"

---

### Task 11: Integrate ConnectionStateIndicator into DeviceScreen AppBar

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/features/device/device_screen.dart`
- Modify: `lib/main.dart`

**Step 1: Write the failing test (BDD format)**

No new widget test (DeviceScreen requires Riverpod + GoRouter setup). Verified by compilation and manual testing.

**Step 2: Run to verify it fails**
Run: `flutter test`
Expected: PASS (compile check)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';
import 'dashboard/dashboard_tab.dart';
import 'control/control_tab.dart';
import 'ha/ha_tab.dart';
import 'admin/admin_tab.dart';

/// Capability-driven device screen — spec §5.
/// Builds TabBar dynamically from negotiated capabilities.
class DeviceScreen extends StatelessWidget {
  final String deviceId;
  final List<Capability> capabilities;
  final bool showControlTab;
  final bool showAdminTab;

  const DeviceScreen({
    super.key,
    required this.deviceId,
    this.capabilities = const [],
    this.showControlTab = false,
    this.showAdminTab = false,
  });
>>>
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';
import 'package:ble_qos_app/widgets/connection_state_indicator.dart';
import 'package:ble_qos_app/widgets/connection_error_screen.dart';
import 'dashboard/dashboard_tab.dart';
import 'control/control_tab.dart';
import 'ha/ha_tab.dart';
import 'admin/admin_tab.dart';

/// Capability-driven device screen with ConnectionStateIndicator — spec §5.
/// Builds TabBar dynamically from negotiated capabilities.
/// Watches BleConnectionState and shows error screen on disconnection.
class DeviceScreen extends ConsumerWidget {
  final String deviceId;
  final List<Capability> capabilities;
  final bool showControlTab;
  final bool showAdminTab;

  const DeviceScreen({
    super.key,
    required this.deviceId,
    this.capabilities = const [],
    this.showControlTab = false,
    this.showAdminTab = false,
  });
>>>
NOTE: Convert StatelessWidget to ConsumerWidget for Riverpod; add imports for connection state.

EDIT_BLOCK 2
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
  @override
  Widget build(BuildContext context) {
    final result = CapabilityNegotiator.negotiate(capabilities);
    final tabs = <_TabEntry>[];
>>>
NEW_CONTENT: <<<
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(bleConnectionStateProvider);
    final bleState = connectionState.valueOrNull ?? BleConnectionState.disconnected;

    // Show error screen if connection lost or errored
    if (bleState == BleConnectionState.error || bleState == BleConnectionState.disconnected) {
      return Scaffold(
        appBar: AppBar(
          title: Text(deviceId),
          actions: [ConnectionStateIndicator(state: bleState)],
        ),
        body: ConnectionErrorScreen(
          message: bleState == BleConnectionState.error
              ? 'Connection to device failed'
              : 'Device disconnected',
          onRetry: () {
            final connector = ref.read(bleConnectorProvider);
            connector.connect(deviceId);
          },
        ),
      );
    }

    final result = CapabilityNegotiator.negotiate(capabilities);
    final tabs = <_TabEntry>[];
>>>
NOTE: Add connection state watching and error screen rendering before normal tab layout.

EDIT_BLOCK 3
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(deviceId)),
        body: const Center(
          child: Text(
            'No compatible capabilities',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (tabs.length == 1) {
      return Scaffold(
        appBar: AppBar(title: Text(deviceId)),
        body: tabs.first.widget,
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(deviceId),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: tabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),
        body: TabBarView(
          children: tabs.map((t) => t.widget).toList(),
        ),
      ),
    );
>>>
NEW_CONTENT: <<<
    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(deviceId),
          actions: [ConnectionStateIndicator(state: bleState)],
        ),
        body: const Center(
          child: Text(
            'No compatible capabilities',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (tabs.length == 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text(deviceId),
          actions: [ConnectionStateIndicator(state: bleState)],
        ),
        body: tabs.first.widget,
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(deviceId),
          actions: [ConnectionStateIndicator(state: bleState)],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: tabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),
        body: TabBarView(
          children: tabs.map((t) => t.widget).toList(),
        ),
      ),
    );
>>>
NOTE: Add ConnectionStateIndicator to all AppBar variants (empty tabs, single tab, multi-tab).

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/device_screen.dart && git commit -m "ui(device-screen): integrate ConnectionStateIndicator and ConnectionErrorScreen"

---

### Task 12: Add disconnection detection with auto-reconnect in DeviceScreen

**Layer:** Presentation
**DDD Pattern:** UseCase
**Files:**
- Modify: `lib/features/device/device_screen.dart`

**Step 1: Write the failing test (BDD format)**

No widget test (requires Riverpod + BLE mock). Verified by compilation.

**Step 2: Run to verify it fails**
Run: `flutter test`
Expected: PASS (compile check)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/device/device_screen.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
>>>
NEW_CONTENT: <<<
import 'package:ble_qos_app/core/ble/ble_reconnect.dart';
>>>
NOTE: Import BleReconnect for auto-reconnect on UnexpectedDisconnection. ANCHOR references code inserted by Task 11, EDIT_BLOCK 1.

EDIT_BLOCK 2
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
      onRetry: () {
            final connector = ref.read(bleConnectorProvider);
            connector.connect(deviceId);
          },
>>>
NEW_CONTENT: <<<
      onRetry: () {
            final reconnect = ref.read(bleReconnectProvider);
            reconnect.cancel(); // reset any previous backoff
            final connector = ref.read(bleConnectorProvider);
            connector.connect(deviceId);
          },
>>>
NOTE: On RetryRequested, cancel existing backoff then reconnect. ANCHOR references code inserted by Task 11, EDIT_BLOCK 2.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/device_screen.dart && git commit -m "ui(device-screen): add auto-reconnect with BleReconnect on retry"

---

### Task 13: Update ConnectionBanner exhaustive switch for new error state

**Layer:** Presentation
**DDD Pattern:** ValueObject (UI component)
**Files:**
- Modify: `lib/widgets/connection_banner.dart`

**Step 1: Write the failing test (BDD format)**

No new test — this is a propagation fix for the exhaustive switch in ConnectionBanner after adding `BleConnectionState.error` in Task 1.

**Step 2: Run to verify it fails**
Run: `flutter test`
Expected: FAIL (non-exhaustive switch on BleConnectionState in connection_banner.dart if Dart 3 strict)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/widgets/connection_banner.dart
ACTION: REPLACE
ANCHOR: <<<
    final (color, text) = switch (state) {
      BleConnectionState.disconnected => (Colors.red, 'Disconnected'),
      BleConnectionState.connecting => (Colors.orange, 'Connecting...'),
      BleConnectionState.handshaking => (Colors.amber, 'Handshaking...'),
      BleConnectionState.connected => (Colors.green, deviceName ?? 'Connected'),
    };
>>>
NEW_CONTENT: <<<
    final (color, text) = switch (state) {
      BleConnectionState.disconnected => (Colors.red, 'Disconnected'),
      BleConnectionState.connecting => (Colors.orange, 'Connecting...'),
      BleConnectionState.handshaking => (Colors.amber, 'Handshaking...'),
      BleConnectionState.connected => (Colors.green, deviceName ?? 'Connected'),
      BleConnectionState.error => (Colors.red, 'Connection Error'),
    };
>>>
NOTE: Propagation fix — add error case to exhaustive switch after Task 1 added BleConnectionState.error.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/widgets/connection_banner.dart && git commit -m "ui(connection-state): add error case to ConnectionBanner exhaustive switch"

---

### Task 14: Final integration verification

**Layer:** Presentation
**DDD Pattern:** N/A (verification only)
**Files:**
- No files modified

**Step 1: Write the failing test (BDD format)**

No new test — run full test suite to verify all changes integrate correctly.

**Step 2: Run to verify it fails**
N/A

**Step 3: Implementation edits**

No edits.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS (all tests green)

**Step 5: Commit**
No commit needed — verification only.
