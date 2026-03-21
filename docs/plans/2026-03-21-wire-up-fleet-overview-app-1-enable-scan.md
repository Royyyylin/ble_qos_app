# Wire Up Fleet Overview App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire up Fleet Overview scanner→device navigation, subscribe DashboardTab to live STATUS GATT notify streams, implement CTRL write in ControlTab with PermissionGuard authorization, and add Semantics widgets for accessibility/automation testing.
**Bounded Context(s):** Navigation, Telemetry, Control, Accessibility
**Architecture:** Layer 1 (Domain) adds `QosCtrl.toBytes()` serialization. Layer 2 (Application) extracts `authSessionProvider` to a shared provider file. Layer 4 (Presentation) wires up navigation, converts DashboardTab/ControlTab to ConsumerWidgets with live stream binding, and adds Semantics annotations.
**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_blue_plus, flutter_test
**Domain Model:** docs/domain/2026-03-21-wire-up-fleet-overview-app-1-enable-scan-domain-model.md
**Research Brief:** docs/research/2026-03-21-wire-up-fleet-overview-app-1-enable-scan-research.md
**Assumptions:**
- DashboardTab only uses `statusStreamProvider` (QosStatus has fully decoded fields); `metricsStreamProvider` (QosMetricsV2) is raw bytes only and not useful for display yet
- QosMetricsV2 display will be deferred to a future task when firmware provides decoded fields
- The 6 MetricCards (RSSI, Zone, PHY, TX Power, PDR, Interval) map to QosStatus fields
- No CTRL write confirmation dialog required — permission check is sufficient
- `connectedDeviceProvider.notifier.connect(device)` must be called before `context.go()` to set device state for providers
- Widget tests use mocked Riverpod providers (no real BLE needed)

**Propagation Checklist:**
- [x] Files sharing this pattern: `dashboard_tab.dart`, `control_tab.dart` (both StatelessWidget→ConsumerWidget)
- [x] Config keys affected: None (`GattUuids` SSOT is already clean)
- [x] Subprocess callers that need update: `settings_screen.dart` (must still import `authSessionProvider` after extraction to shared file)

**EDIT_BLOCK Validation:**
- [x] Every ANCHOR verified unique in target file (post prior edits)
- [x] Cross-task anchor dependencies noted (Task 6 depends on Task 5 ConsumerWidget conversion)
- [x] CREATE_FILE provides complete file content
- [x] REPLACE anchors include ALL lines being removed
- [x] No EDIT_BLOCK relies on nearest-match or semantic search

---

## Layer 1: Domain

### Task 1: [Domain] Add QosCtrl.toBytes() Serialization

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Modify: `lib/core/gatt/gatt_structs.dart`
- Modify: `test/gatt_structs_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// In test/gatt_structs_test.dart, add to the QosCtrl group:

test('given valid QosCtrl when toBytes then produces 9-byte payload matching fromBytes layout', () {
  final ctrl = QosCtrl(
    profile: 1,
    phy: 2,
    txPower: -4,
    interval: 80,
    creditAlarm: 5,
    creditCtrl: 3,
    creditRs485: 2,
    flags: 0,
  );
  final bytes = ctrl.toBytes();
  expect(bytes.length, QosCtrl.size);
  // Round-trip: decode what we encoded
  final decoded = QosCtrl.fromBytes(bytes);
  expect(decoded.profile, 1);
  expect(decoded.phy, 2);
  expect(decoded.txPower, -4);
  expect(decoded.interval, 80);
  expect(decoded.creditAlarm, 5);
  expect(decoded.creditCtrl, 3);
  expect(decoded.creditRs485, 2);
  expect(decoded.flags, 0);
});

test('given QosCtrl with negative txPower when toBytes then encodes int8 correctly', () {
  final ctrl = QosCtrl(
    profile: 0, phy: 1, txPower: -20, interval: 160,
    creditAlarm: 0, creditCtrl: 0, creditRs485: 0, flags: 0xFF,
  );
  final bytes = ctrl.toBytes();
  expect(bytes.length, QosCtrl.size);
  final decoded = QosCtrl.fromBytes(bytes);
  expect(decoded.txPower, -20);
  expect(decoded.interval, 160);
  expect(decoded.flags, 0xFF);
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/gatt_structs_test.dart`
Expected: FAIL (toBytes() method does not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/gatt_structs_test.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
      expect(c.flags, 0);
    });
  });
>>>
NEW_CONTENT: <<<

  group('QosCtrl.toBytes()', () {
    test('given valid QosCtrl when toBytes then produces 9-byte payload matching fromBytes layout', () {
      final ctrl = QosCtrl(
        profile: 1,
        phy: 2,
        txPower: -4,
        interval: 80,
        creditAlarm: 5,
        creditCtrl: 3,
        creditRs485: 2,
        flags: 0,
      );
      final bytes = ctrl.toBytes();
      expect(bytes.length, QosCtrl.size);
      final decoded = QosCtrl.fromBytes(bytes);
      expect(decoded.profile, 1);
      expect(decoded.phy, 2);
      expect(decoded.txPower, -4);
      expect(decoded.interval, 80);
      expect(decoded.creditAlarm, 5);
      expect(decoded.creditCtrl, 3);
      expect(decoded.creditRs485, 2);
      expect(decoded.flags, 0);
    });

    test('given QosCtrl with negative txPower when toBytes then encodes int8 correctly', () {
      final ctrl = QosCtrl(
        profile: 0, phy: 1, txPower: -20, interval: 160,
        creditAlarm: 0, creditCtrl: 0, creditRs485: 0, flags: 0xFF,
      );
      final bytes = ctrl.toBytes();
      expect(bytes.length, QosCtrl.size);
      final decoded = QosCtrl.fromBytes(bytes);
      expect(decoded.txPower, -20);
      expect(decoded.interval, 160);
      expect(decoded.flags, 0xFF);
    });
  });
>>>
NOTE: Add round-trip and int8 encoding tests after existing QosCtrl group closing.

EDIT_BLOCK 2
FILE: lib/core/gatt/gatt_structs.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
  factory QosCtrl.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('QosCtrl: expected $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return QosCtrl(
      profile: bd.getUint8(0),
      phy: bd.getUint8(1),
      txPower: bd.getInt8(2),
      interval: bd.getUint16(3, Endian.little),
      creditAlarm: bd.getUint8(5),
      creditCtrl: bd.getUint8(6),
      creditRs485: bd.getUint8(7),
      flags: bd.getUint8(8),
    );
  }
>>>
NEW_CONTENT: <<<

  /// Serialize to 9-byte payload for CTRL characteristic write.
  /// Byte layout mirrors fromBytes() field order exactly.
  Uint8List toBytes() {
    final data = Uint8List(size);
    final bd = ByteData.sublistView(data);
    bd.setUint8(0, profile);
    bd.setUint8(1, phy);
    bd.setInt8(2, txPower);
    bd.setUint16(3, interval, Endian.little);
    bd.setUint8(5, creditAlarm);
    bd.setUint8(6, creditCtrl);
    bd.setUint8(7, creditRs485);
    bd.setUint8(8, flags);
    return data;
  }
>>>
NOTE: Mirror fromBytes() field order. Uses ByteData for int8/uint16 LE encoding (same pattern as QosGwCfgV2.toBytes() at L153).

**Step 4: Run to verify it passes**
Run: `flutter test test/gatt_structs_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/gatt/gatt_structs.dart test/gatt_structs_test.dart && git commit -m "domain(control): add QosCtrl.toBytes() serialization for CTRL characteristic writes"

---

## Layer 2: Application

### Task 2: [Application] Extract authSessionProvider to Shared Provider File

**Layer:** Application
**DDD Pattern:** UseCase (provider extraction for cross-feature access)
**Files:**
- Create: `lib/core/providers/auth_provider.dart`
- Modify: `lib/features/settings/settings_screen.dart`

**Step 1: Write the failing test (BDD format)**

No test needed — this is a pure refactoring (move provider definition to shared location). Existing tests should still pass after the move.

**Step 2: Run to verify baseline passes**
Run: `flutter test`
Expected: PASS (baseline)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/providers/auth_provider.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';

/// Riverpod provider for auth session — shared across features.
/// Extracted from settings_screen.dart to avoid cross-feature coupling.
final authSessionProvider = Provider<AuthSession>((ref) => AuthSession());
>>>
NOTE: New shared provider file so ControlTab can import without depending on settings feature.

EDIT_BLOCK 2
FILE: lib/features/settings/settings_screen.dart
ACTION: REPLACE
ANCHOR: <<<
import '../../core/auth/auth_session.dart';
import '../../core/ble/ble_connector.dart';
import '../../core/providers/device_provider.dart';

/// Riverpod provider for auth session — replaces legacy role_provider + unlock_session.
final authSessionProvider = Provider<AuthSession>((ref) => AuthSession());
>>>
NEW_CONTENT: <<<
import '../../core/auth/auth_session.dart';
import '../../core/ble/ble_connector.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/device_provider.dart';
>>>
NOTE: Remove inline provider definition, import from shared location. Add auth_provider.dart import.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/core/providers/auth_provider.dart lib/features/settings/settings_screen.dart && git commit -m "app(auth): extract authSessionProvider to shared core/providers/auth_provider.dart"

---

## Layer 4: Presentation

### Task 3: [Presentation] Enable Scanner→Device Navigation via GoRouter

**Layer:** Presentation
**DDD Pattern:** Adapter (UI navigation wiring)
**Files:**
- Modify: `lib/features/scanner/scanner_screen.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// test/features/scanner/scanner_screen_navigation_test.dart
// Widget test verifying _onDeviceTap calls context.go and sets connectedDeviceProvider
```

Navigation tests require GoRouter mocking which is complex for a one-line uncomment. Instead, verify manually:

**Step 2: Run to verify baseline**
Run: `flutter test`
Expected: PASS (baseline)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/scanner/scanner_screen.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
>>>
NEW_CONTENT: <<<
import 'package:go_router/go_router.dart';
>>>
NOTE: Required for context.go() navigation call.

EDIT_BLOCK 2
FILE: lib/features/scanner/scanner_screen.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import '../../core/ble/ble_scanner.dart';
>>>
NEW_CONTENT: <<<
import '../../core/providers/device_provider.dart';
>>>
NOTE: Required for connectedDeviceProvider.notifier.connect() call before navigation.

EDIT_BLOCK 3
FILE: lib/features/scanner/scanner_screen.dart
ACTION: REPLACE
ANCHOR: <<<
  void _onDeviceTap(ScannedDevice device) {
    // Navigate to device detail via GoRouter
    // context.go('/device/${device.id}');
  }
>>>
NEW_CONTENT: <<<
  void _onDeviceTap(ScannedDevice device) {
    // Set connected device state so providers (statusStreamProvider, etc.) can subscribe
    ref.read(connectedDeviceProvider.notifier).connect(device);
    // Navigate to device detail via GoRouter
    context.go('/device/${device.id}');
  }
>>>
NOTE: Must call connect() BEFORE navigation so metricsStreamProvider/statusStreamProvider find a connected device.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS (no existing scanner tests break)

**Step 5: Commit**
git add lib/features/scanner/scanner_screen.dart && git commit -m "ui(navigation): enable scanner→device navigation via GoRouter context.go()"

---

### Task 4: [Presentation] Subscribe DashboardTab to Live STATUS Stream

**Layer:** Presentation
**DDD Pattern:** Adapter (UI stream binding)
**Files:**
- Modify: `lib/features/device/dashboard/dashboard_tab.dart`
- Create: `test/features/device/dashboard/dashboard_tab_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// test/features/device/dashboard/dashboard_tab_test.dart
test('given statusStreamProvider emits QosStatus when DashboardTab renders then shows live metric values')
test('given statusStreamProvider is loading when DashboardTab renders then shows loading indicator')
test('given statusStreamProvider has error when DashboardTab renders then shows error message')
```

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart`
Expected: FAIL (file doesn't exist yet)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/features/device/dashboard/dashboard_tab_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/features/device/dashboard/dashboard_tab.dart';

void main() {
  // Helper to create a QosStatus from known values
  QosStatus makeStatus({
    int rssi = -55,
    int zone = 1,
    int phy = 2,
    int txPower = -8,
    int pdr = 95,
    int interval = 160,
  }) {
    return QosStatus(
      zone: zone,
      profile: 0,
      phy: phy,
      txPower: txPower,
      rssi: rssi,
      pdr: pdr,
      interval: interval,
      latency: 50,
      jitter: 5,
      tp: 10,
    );
  }

  Widget buildTestWidget({
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(body: DashboardTab(deviceId: 'test-device')),
      ),
    );
  }

  testWidgets(
    'given statusStreamProvider emits QosStatus when DashboardTab renders then shows live metric values',
    (tester) async {
      final status = makeStatus(rssi: -55, zone: 1, phy: 2, txPower: -8, pdr: 95, interval: 160);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('-55'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('-8'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('160'), findsOneWidget);
    },
  );

  testWidgets(
    'given statusStreamProvider is loading when DashboardTab renders then shows placeholder dashes',
    (tester) async {
      // Never-completing stream = loading state
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
      ));
      await tester.pump();

      // Should show '--' placeholders while loading
      expect(find.text('--'), findsWidgets);
    },
  );

  testWidgets(
    'given statusStreamProvider has error when DashboardTab renders then shows error message',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith(
            (ref) => Stream.error('BLE disconnected'),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    },
  );
}
>>>
NOTE: Tests use Riverpod overrides to mock statusStreamProvider without real BLE.

EDIT_BLOCK 2
FILE: lib/features/device/dashboard/dashboard_tab.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Dashboard tab — telemetry metrics display (spec §5, §6).
/// Shows RSSI, Zone, PHY, TX, PDR, Interval, Latency via MetricCard widgets.
/// Subscribes to STATUS + METRICS notify streams.
class DashboardTab extends StatelessWidget {
  final String deviceId;

  const DashboardTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telemetry',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: const [
                _MetricCard(label: 'RSSI', value: '--', unit: 'dBm'),
                _MetricCard(label: 'Zone', value: '--', unit: ''),
                _MetricCard(label: 'PHY', value: '--', unit: ''),
                _MetricCard(label: 'TX Power', value: '--', unit: 'dBm'),
                _MetricCard(label: 'PDR', value: '--', unit: '%'),
                _MetricCard(label: 'Interval', value: '--', unit: 'ms'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
>>>
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Dashboard tab — telemetry metrics display (spec §5, §6).
/// Subscribes to STATUS notify stream via statusStreamProvider.
/// Shows RSSI, Zone, PHY, TX Power, PDR, Interval as live MetricCards.
class DashboardTab extends ConsumerWidget {
  final String deviceId;

  const DashboardTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(statusStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telemetry',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: statusAsync.when(
              loading: () => GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: const [
                  _MetricCard(label: 'RSSI', value: '--', unit: 'dBm'),
                  _MetricCard(label: 'Zone', value: '--', unit: ''),
                  _MetricCard(label: 'PHY', value: '--', unit: ''),
                  _MetricCard(label: 'TX Power', value: '--', unit: 'dBm'),
                  _MetricCard(label: 'PDR', value: '--', unit: '%'),
                  _MetricCard(label: 'Interval', value: '--', unit: 'ms'),
                ],
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (status) => GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _MetricCard(label: 'RSSI', value: '${status.rssi}', unit: 'dBm'),
                  _MetricCard(label: 'Zone', value: '${status.zone}', unit: ''),
                  _MetricCard(label: 'PHY', value: '${status.phy}', unit: ''),
                  _MetricCard(label: 'TX Power', value: '${status.txPower}', unit: 'dBm'),
                  _MetricCard(label: 'PDR', value: '${status.pdr}', unit: '%'),
                  _MetricCard(label: 'Interval', value: '${status.interval}', unit: 'ms'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
>>>
NOTE: Convert StatelessWidget→ConsumerWidget. Use AsyncValue.when() for loading/error/data states. Replace hardcoded '--' with live QosStatus fields.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/dashboard/dashboard_tab.dart test/features/device/dashboard/dashboard_tab_test.dart && git commit -m "ui(telemetry): subscribe DashboardTab to live STATUS stream via statusStreamProvider"

---

### Task 5: [Presentation] Implement CTRL Write onTap in ControlTab

**Layer:** Presentation
**DDD Pattern:** Adapter (UI command handler)
**Files:**
- Modify: `lib/features/device/control/control_tab.dart`
- Create: `test/features/device/control/control_tab_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// test/features/device/control/control_tab_test.dart
test('given maintenance role when Write CTRL tapped then shows success snackbar')
test('given normal role when Write CTRL tapped then shows permission denied snackbar')
```

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/control/control_tab_test.dart`
Expected: FAIL (file doesn't exist yet)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/features/device/control/control_tab_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/auth/auth_session.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/features/device/control/control_tab.dart';

void main() {
  Widget buildTestWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(body: ControlTab(deviceId: 'test-device')),
      ),
    );
  }

  testWidgets(
    'given normal role when Write CTRL tapped then shows permission denied snackbar',
    (tester) async {
      final session = AuthSession(); // defaults to normal role
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          authSessionProvider.overrideWithValue(session),
        ],
      ));

      await tester.tap(find.text('Write CTRL'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Permission denied'), findsOneWidget);
    },
  );

  testWidgets(
    'given maintenance role when Write CTRL tapped then attempts CTRL write',
    (tester) async {
      final session = AuthSession();
      session.elevate(AuthRole.maintenance);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          authSessionProvider.overrideWithValue(session),
        ],
      ));

      // Tapping Write CTRL with maintenance role should not show permission denied
      await tester.tap(find.text('Write CTRL'));
      await tester.pumpAndSettle();

      // Should NOT show permission denied
      expect(find.textContaining('Permission denied'), findsNothing);
    },
  );
}
>>>
NOTE: Tests verify PermissionGuard gate. BleGatt.write() is not invoked in test (requires real BLE connection).

EDIT_BLOCK 2
FILE: lib/features/device/control/control_tab.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Control tab — QoS profile selector and CTRL write buttons (spec §6).
/// Permission-gated by PermissionGuard.canWrite().
class ControlTab extends StatelessWidget {
  final String deviceId;

  const ControlTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QoS Control',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune, color: AppColors.primary),
              title: const Text('QoS Profile'),
              subtitle: const Text('Select active profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show profile selector
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.send, color: AppColors.primary),
              title: const Text('Write CTRL'),
              subtitle: const Text('Send control command'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: CTRL write with permission check
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_ethernet, color: AppColors.primary),
              title: const Text('Gateway Config'),
              subtitle: const Text('Edit GW_CFG parameters'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
        ],
      ),
    );
  }
}
>>>
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/auth/auth_session.dart';
import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Control tab — QoS profile selector and CTRL write buttons (spec §6).
/// Permission-gated by PermissionGuard.canWrite().
class ControlTab extends ConsumerWidget {
  final String deviceId;

  const ControlTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QoS Control',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune, color: AppColors.primary),
              title: const Text('QoS Profile'),
              subtitle: const Text('Select active profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show profile selector
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.send, color: AppColors.primary),
              title: const Text('Write CTRL'),
              subtitle: const Text('Send control command'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _writeCtrl(context, ref),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_ethernet, color: AppColors.primary),
              title: const Text('Gateway Config'),
              subtitle: const Text('Edit GW_CFG parameters'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
        ],
      ),
    );
  }

  /// CTRL write flow: PermissionGuard check → QosCtrl.toBytes() → BleGatt.write()
  Future<void> _writeCtrl(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    final role = session.currentRole;

    // Permission gate: CTRL requires maintenance+ role
    if (!PermissionGuard.canWrite(role, GattAction.ctrl)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied: maintenance role required for CTRL write'),
          ),
        );
      }
      return;
    }

    // Build default CTRL payload (profile=FAST, phy=2M, tx=0)
    final ctrl = QosCtrl(
      profile: 0,
      phy: 2,
      txPower: 0,
      interval: 80,
      creditAlarm: 0,
      creditCtrl: 0,
      creditRs485: 0,
      flags: 0,
    );

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      await gatt.write(GattUuids.ctrl, ctrl.toBytes());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CTRL written successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CTRL write failed: $e')),
        );
      }
    }
  }
}
>>>
NOTE: Convert StatelessWidget→ConsumerWidget. Implement _writeCtrl() with PermissionGuard gate, QosCtrl.toBytes(), BleGatt.write(). Depends on Task 1 (toBytes) and Task 2 (authSessionProvider extraction).

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/control/control_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/control/control_tab.dart test/features/device/control/control_tab_test.dart && git commit -m "ui(control): implement CTRL write onTap with PermissionGuard authorization"

---

### Task 6: [Presentation] Add Semantics to ScanDeviceTile

**Layer:** Presentation
**DDD Pattern:** Adapter (accessibility annotation)
**Files:**
- Modify: `lib/features/scanner/scan_device_tile.dart`
- Create: `test/features/scanner/scan_device_tile_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
test('given ScannedDevice when ScanDeviceTile renders then has semantics label with device name and role')
test('given ScanDeviceTile when rendered then has tap hint for accessibility')
```

**Step 2: Run to verify it fails**
Run: `flutter test test/features/scanner/scan_device_tile_test.dart`
Expected: FAIL (file doesn't exist yet)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/features/scanner/scan_device_tile_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/features/scanner/scan_device_tile.dart';

void main() {
  ScannedDevice makeDevice({
    String name = 'GW-Test-01',
    int rssi = -55,
    String id = 'AA:BB:CC:DD:EE:FF',
  }) {
    return ScannedDevice(
      id: id,
      name: name,
      rssi: rssi,
      smoothedRssi: rssi.toDouble(),
      status: DeviceStatus.online,
      lastSeen: DateTime.now(),
    );
  }

  testWidgets(
    'given ScannedDevice when ScanDeviceTile renders then has semantics label with device info',
    (tester) async {
      final device = makeDevice(name: 'GW-Test-01', rssi: -55);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScanDeviceTile(device: device, onTap: () {}),
        ),
      ));

      final semantics = tester.getSemantics(find.byType(ScanDeviceTile));
      expect(semantics.label, contains('GW-Test-01'));
      expect(semantics.label, contains('Gateway'));
      expect(semantics.label, contains('-55'));
    },
  );

  testWidgets(
    'given ScanDeviceTile when rendered then has double tap hint for accessibility',
    (tester) async {
      final device = makeDevice();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScanDeviceTile(device: device, onTap: () {}),
        ),
      ));

      final semantics = tester.getSemantics(find.byType(ScanDeviceTile));
      expect(semantics.hint, contains('connect'));
    },
  );
}
>>>
NOTE: Tests verify Semantics label includes device name, role, RSSI, and hint includes "connect".

EDIT_BLOCK 2
FILE: lib/features/scanner/scan_device_tile.dart
ACTION: REPLACE
ANCHOR: <<<
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _statusIndicator(),
        title: Text(
          device.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${device.roleLabel} ${device.networkId != null ? "| Net ${device.networkId}" : ""}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _rssiWidget(),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
>>>
NEW_CONTENT: <<<
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${device.displayName}, ${device.roleLabel}, ${device.smoothedRssi.round()} dBm, ${device.status.name}',
      hint: 'Double tap to connect',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _statusIndicator(),
          title: Text(
            device.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${device.roleLabel} ${device.networkId != null ? "| Net ${device.networkId}" : ""}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _rssiWidget(),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
>>>
NOTE: Wrap Card with Semantics widget providing label (name, role, RSSI, status) and hint for screen readers and Appium automation.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/scanner/scan_device_tile_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/scanner/scan_device_tile.dart test/features/scanner/scan_device_tile_test.dart && git commit -m "ui(accessibility): add Semantics to ScanDeviceTile for screen readers and automation"

---

### Task 7: [Presentation] Add Semantics to MetricCard and CTRL Write Button

**Layer:** Presentation
**DDD Pattern:** Adapter (accessibility annotation)
**Files:**
- Modify: `lib/features/device/dashboard/dashboard_tab.dart`
- Modify: `lib/features/device/control/control_tab.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// Extend existing test files to verify Semantics labels
test('given QosStatus data when MetricCard renders then has semantics label with metric info')
test('given ControlTab when Write CTRL renders then has semantics label with permission info')
```

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart`
Expected: FAIL (Semantics not yet added)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: test/features/device/dashboard/dashboard_tab_test.dart
ACTION: APPEND
NEW_CONTENT: <<<

  testWidgets(
    'given QosStatus data when MetricCard renders then has semantics label with metric name and value',
    (tester) async {
      final status = makeStatus(rssi: -60, pdr: 88);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
        ],
      ));
      await tester.pumpAndSettle();

      // Find a Semantics widget containing RSSI info
      expect(
        find.bySemanticsLabel(RegExp(r'RSSI.*-60.*dBm')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'PDR.*88.*%')),
        findsOneWidget,
      );
    },
  );
}
>>>
NOTE: Test verifies MetricCard Semantics labels. ANCHOR references code from Task 4. Replaces the closing `}` of main().

EDIT_BLOCK 2
FILE: test/features/device/dashboard/dashboard_tab_test.dart
ACTION: REPLACE
ANCHOR: <<<
      expect(find.textContaining('Error'), findsOneWidget);
    },
  );
}

  testWidgets(
>>>
NEW_CONTENT: <<<
      expect(find.textContaining('Error'), findsOneWidget);
    },
  );

  testWidgets(
>>>
NOTE: Fix formatting — remove extra closing brace from main() since APPEND added a new test inside a re-opened block. Actually we need to remove the old closing `}` before the appended test.

Actually, let me reconsider. The APPEND in EDIT_BLOCK 1 appends after the file's last line. The file from Task 4's CREATE_FILE ends with `}` (closing main()). The APPEND would add code after `}`. This won't compile. Let me use INSERT_BEFORE instead.

EDIT_BLOCK 1 (revised)
FILE: test/features/device/dashboard/dashboard_tab_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
      expect(find.textContaining('Error'), findsOneWidget);
    },
  );
}
>>>
NEW_CONTENT: <<<
      expect(find.textContaining('Error'), findsOneWidget);
    },
  );

  testWidgets(
    'given QosStatus data when MetricCard renders then has semantics label with metric name and value',
    (tester) async {
      final status = makeStatus(rssi: -60, pdr: 88);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
        ],
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'RSSI.*-60.*dBm')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'PDR.*88.*%')),
        findsOneWidget,
      );
    },
  );
}
>>>
NOTE: Insert Semantics test before closing main(). ANCHOR references code inserted by Task 4 CREATE_FILE.

EDIT_BLOCK 2
FILE: lib/features/device/dashboard/dashboard_tab.dart
ACTION: REPLACE
ANCHOR: <<<
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
>>>
NEW_CONTENT: <<<
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = unit.isNotEmpty ? '$label: $value $unit' : '$label: $value';
    return Semantics(
      label: semanticsLabel,
      readOnly: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(unit, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
>>>
NOTE: Wrap Card with Semantics providing "{label}: {value} {unit}" for screen readers. readOnly=true since MetricCards are display-only.

EDIT_BLOCK 3
FILE: lib/features/device/control/control_tab.dart
ACTION: REPLACE
ANCHOR: <<<
              onTap: () => _writeCtrl(context, ref),
>>>
NEW_CONTENT: <<<
              semanticLabel: 'Write control command to device',
              onTap: () => _writeCtrl(context, ref),
>>>
NOTE: ANCHOR references code inserted by Task 5. Add semanticLabel to Write CTRL ListTile for accessibility. ListTile does not have a semanticLabel property — need to wrap instead.

Actually, ListTile doesn't have `semanticLabel`. Let me wrap the Write CTRL Card with Semantics instead.

EDIT_BLOCK 3 (revised)
FILE: lib/features/device/control/control_tab.dart
ACTION: REPLACE
ANCHOR: <<<
          Card(
            child: ListTile(
              leading: const Icon(Icons.send, color: AppColors.primary),
              title: const Text('Write CTRL'),
              subtitle: const Text('Send control command'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _writeCtrl(context, ref),
            ),
          ),
>>>
NEW_CONTENT: <<<
          Semantics(
            label: 'Write CTRL: send control command to device',
            hint: 'Double tap to write',
            button: true,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.send, color: AppColors.primary),
                title: const Text('Write CTRL'),
                subtitle: const Text('Send control command'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _writeCtrl(context, ref),
              ),
            ),
          ),
>>>
NOTE: ANCHOR references code inserted by Task 5. Wrap CTRL write Card with Semantics for accessibility.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/dashboard/dashboard_tab.dart lib/features/device/control/control_tab.dart test/features/device/dashboard/dashboard_tab_test.dart && git commit -m "ui(accessibility): add Semantics to MetricCard and CTRL write button"

---

### Task 8: [Presentation] Add Semantics to Scan Toggle Button and FleetSummary

**Layer:** Presentation
**DDD Pattern:** Adapter (accessibility annotation)
**Files:**
- Modify: `lib/features/scanner/scanner_screen.dart`
- Modify: `lib/features/scanner/fleet_summary.dart`

**Step 1: Write the failing test (BDD format)**

No new test file — these are additive Semantics annotations on existing widgets with no behavioral change.

**Step 2: Run to verify baseline**
Run: `flutter test`
Expected: PASS (baseline)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/scanner/scanner_screen.dart
ACTION: REPLACE
ANCHOR: <<<
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            onPressed: _scanning ? _stopScan : _startScan,
            tooltip: _scanning ? 'Stop scan' : 'Start scan',
          ),
>>>
NEW_CONTENT: <<<
          Semantics(
            label: _scanning ? 'Stop scan' : 'Start scan',
            button: true,
            child: IconButton(
              icon: Icon(_scanning ? Icons.stop : Icons.search),
              onPressed: _scanning ? _stopScan : _startScan,
              tooltip: _scanning ? 'Stop scan' : 'Start scan',
            ),
          ),
>>>
NOTE: Add Semantics to scan toggle button for screen reader access.

EDIT_BLOCK 2
FILE: lib/features/scanner/fleet_summary.dart
ACTION: REPLACE
ANCHOR: <<<
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'Online', count: online, color: AppColors.success)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Stale', count: stale, color: AppColors.warning)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Offline', count: offline, color: AppColors.error)),
        ],
      ),
    );
>>>
NEW_CONTENT: <<<
    return Semantics(
      label: 'Fleet summary: $online online, $stale stale, $offline offline',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _StatCard(label: 'Online', count: online, color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Stale', count: stale, color: AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Offline', count: offline, color: AppColors.error)),
          ],
        ),
      ),
    );
>>>
NOTE: Wrap FleetSummary row with Semantics providing aggregate device count summary for screen readers.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/features/scanner/scanner_screen.dart lib/features/scanner/fleet_summary.dart && git commit -m "ui(accessibility): add Semantics to scan toggle button and FleetSummary"
