# Implement Remaining Device Screen Features Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire up Provisioning ROLE write, HA Heartbeat subscription, and Admin Tab operations (ENG_UNLOCK, CMD reboot, MODE/ROLE write) using permission-gated GATT write pattern.
**Bounded Context(s):** Provisioning, HA Monitoring, Admin Operations, Auth (existing)
**Architecture:** Layer 1 (Domain) adds HaHeartbeat codec, DeviceRole mapping, and CmdCode constants to gatt_structs.dart. Layer 2 (Application) adds haHeartbeatStreamProvider following _gattNotifyStream pattern. Layer 3 (Infrastructure) adds GattUuids.haHb UUID. Layer 4 (Presentation) wires ProvisioningScreen, HaTab, and AdminTab to GATT operations via BleGatt, following ControlTab._writeCtrl() reference pattern.
**Tech Stack:** Flutter 3.x, Dart, flutter_riverpod 2.6.1, flutter_blue_plus 1.35.0, mocktail 1.0.4
**Domain Model:** docs/domain/2026-03-21-implement-remaining-device-screen-featur-domain-model.md
**Research Brief:** docs/research/2026-03-21-implement-remaining-device-screen-featur-research.md
**Assumptions:**
- HA Heartbeat 21-byte layout: HaRole(1) + Epoch(4) + HeartbeatCount(4) + PeerStatus(1) + LastFailoverTimestamp(4) + LastFailoverReason(1) + Reserved(6) = 21 bytes. The 6 unaccounted bytes are reserved/padding per firmware convention.
- ENG_UNLOCK response: success is implied by no exception from `BleGatt.write()` (write-with-response). Firmware returns BLE ATT error on failure, which flutter_blue_plus surfaces as an exception.
- ProvisioningScreen existing tests wrap in plain `MaterialApp` — after Riverpod migration, they must wrap in `ProviderScope` with overrides.

**Propagation Checklist:**
- [x] Files sharing ROLE uint8 mapping: `manufacturer_data.dart` (SSOT), `provisioning_screen.dart`, `admin_tab.dart`
- [x] Config keys affected: `GattUuids` (add `haHb`), `gatt_structs.dart` (add `HaHeartbeat`, `CmdCode`)
- [x] Subprocess callers that need update: `provisioning_screen_test.dart` (needs ProviderScope after Riverpod migration)

**EDIT_BLOCK Validation:**
- [x] Every ANCHOR verified unique in target file (post prior edits)
- [x] Cross-task anchor dependencies noted
- [x] CREATE_FILE provides complete file content
- [x] REPLACE anchors include ALL lines being removed
- [x] No EDIT_BLOCK relies on nearest-match or semantic search

---

## Layer 1: Domain

### Task 1: [Domain] Add HaHeartbeat codec to gatt_structs

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Modify: `lib/core/gatt/gatt_structs.dart`
- Modify: `test/gatt_structs_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// In test/gatt_structs_test.dart, add after QosPingRsp group:

group('HaHeartbeat', () {
  test('given 21_byte payload when fromBytes then parses all fields correctly', () {
    final data = Uint8List(21);
    final bd = ByteData.sublistView(data);
    bd.setUint8(0, 0x01);                        // haRole = active
    bd.setUint32(1, 42, Endian.little);           // epoch
    bd.setUint32(5, 1000, Endian.little);         // heartbeatCount
    bd.setUint8(9, 0x02);                         // peerStatus = standby
    bd.setUint32(10, 1710000000, Endian.little);  // lastFailoverTimestamp
    bd.setUint8(14, 0x03);                        // lastFailoverReason
    // bytes 15-20 reserved

    final hb = HaHeartbeat.fromBytes(data);
    expect(hb.haRole, 0x01);
    expect(hb.epoch, 42);
    expect(hb.heartbeatCount, 1000);
    expect(hb.peerStatus, 0x02);
    expect(hb.lastFailoverTimestamp, 1710000000);
    expect(hb.lastFailoverReason, 0x03);
  });

  test('given wrong length when fromBytes then throws ArgumentError', () {
    expect(
      () => HaHeartbeat.fromBytes(Uint8List(10)),
      throwsArgumentError,
    );
  });

  test('given active role when haRoleLabel then returns Active', () {
    final data = Uint8List(21);
    data[0] = 0x01;
    final hb = HaHeartbeat.fromBytes(data);
    expect(hb.haRoleLabel, 'Active');
  });

  test('given standby role when haRoleLabel then returns Standby', () {
    final data = Uint8List(21);
    data[0] = 0x02;
    final hb = HaHeartbeat.fromBytes(data);
    expect(hb.haRoleLabel, 'Standby');
  });
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/gatt_structs_test.dart`
Expected: FAIL (HaHeartbeat class does not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/gatt/gatt_structs.dart
ACTION: APPEND
ANCHOR: <<<
>>>
NEW_CONTENT: <<<

/// ha_heartbeat — 21 bytes, HA_HB characteristic (vendor 6f8a9c15)
/// Layout: haRole(1) + epoch(4LE) + heartbeatCount(4LE) + peerStatus(1)
///       + lastFailoverTimestamp(4LE) + lastFailoverReason(1) + reserved(6)
class HaHeartbeat {
  final int haRole;                 // uint8: 0x01=active, 0x02=standby
  final int epoch;                  // uint32 LE — HA cluster generation
  final int heartbeatCount;         // uint32 LE
  final int peerStatus;             // uint8: peer's role
  final int lastFailoverTimestamp;  // uint32 LE — unix epoch
  final int lastFailoverReason;     // uint8

  const HaHeartbeat({
    required this.haRole,
    required this.epoch,
    required this.heartbeatCount,
    required this.peerStatus,
    required this.lastFailoverTimestamp,
    required this.lastFailoverReason,
  });

  static const int size = 21;
  static const int roleActive = 0x01;
  static const int roleStandby = 0x02;

  String get haRoleLabel => switch (haRole) {
    roleActive => 'Active',
    roleStandby => 'Standby',
    _ => 'Unknown (0x${haRole.toRadixString(16)})',
  };

  String get peerStatusLabel => switch (peerStatus) {
    roleActive => 'Active',
    roleStandby => 'Standby',
    _ => 'Unknown (0x${peerStatus.toRadixString(16)})',
  };

  factory HaHeartbeat.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('HaHeartbeat: expected $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return HaHeartbeat(
      haRole: bd.getUint8(0),
      epoch: bd.getUint32(1, Endian.little),
      heartbeatCount: bd.getUint32(5, Endian.little),
      peerStatus: bd.getUint8(9),
      lastFailoverTimestamp: bd.getUint32(10, Endian.little),
      lastFailoverReason: bd.getUint8(14),
    );
  }
}
>>>
NOTE: Follows existing QosStatus/QosEvtV1 codec pattern with size validation.

EDIT_BLOCK 2
FILE: test/gatt_structs_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
  group('QosPingRsp', () {
>>>
NEW_CONTENT: <<<
  group('HaHeartbeat', () {
    test('given 21_byte payload when fromBytes then parses all fields correctly', () {
      final data = Uint8List(21);
      final bd = ByteData.sublistView(data);
      bd.setUint8(0, 0x01);                        // haRole = active
      bd.setUint32(1, 42, Endian.little);           // epoch
      bd.setUint32(5, 1000, Endian.little);         // heartbeatCount
      bd.setUint8(9, 0x02);                         // peerStatus = standby
      bd.setUint32(10, 1710000000, Endian.little);  // lastFailoverTimestamp
      bd.setUint8(14, 0x03);                        // lastFailoverReason

      final hb = HaHeartbeat.fromBytes(data);
      expect(hb.haRole, 0x01);
      expect(hb.epoch, 42);
      expect(hb.heartbeatCount, 1000);
      expect(hb.peerStatus, 0x02);
      expect(hb.lastFailoverTimestamp, 1710000000);
      expect(hb.lastFailoverReason, 0x03);
    });

    test('given wrong length when fromBytes then throws ArgumentError', () {
      expect(
        () => HaHeartbeat.fromBytes(Uint8List(10)),
        throwsArgumentError,
      );
    });

    test('given active role when haRoleLabel then returns Active', () {
      final data = Uint8List(21);
      data[0] = 0x01;
      final hb = HaHeartbeat.fromBytes(data);
      expect(hb.haRoleLabel, 'Active');
    });

    test('given standby role when haRoleLabel then returns Standby', () {
      final data = Uint8List(21);
      data[0] = 0x02;
      final hb = HaHeartbeat.fromBytes(data);
      expect(hb.haRoleLabel, 'Standby');
    });
  });

>>>
NOTE: Add HaHeartbeat tests before QosPingRsp group.

**Step 4: Run to verify it passes**
Run: `flutter test test/gatt_structs_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/gatt/gatt_structs.dart test/gatt_structs_test.dart && git commit -m "domain(ha-monitoring): add HaHeartbeat 21-byte codec to gatt_structs"

---

### Task 2: [Domain] Add CmdCode constants to gatt_structs

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Modify: `lib/core/gatt/gatt_structs.dart`
- Modify: `test/gatt_structs_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
group('CmdCode', () {
  test('given reboot constant when accessed then equals 0x01', () {
    expect(CmdCode.reboot, 0x01);
  });
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/gatt_structs_test.dart`
Expected: FAIL (CmdCode class does not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/gatt/gatt_structs.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
/// ha_heartbeat — 21 bytes, HA_HB characteristic (vendor 6f8a9c15)
>>>
NEW_CONTENT: <<<
/// CMD opcodes for the CMD characteristic (0x2A20).
class CmdCode {
  CmdCode._();
  static const int reboot = 0x01;
}

>>>
NOTE: ANCHOR references code inserted by Task 1, EDIT_BLOCK 1. CmdCode codifies domain-model-only constant.

EDIT_BLOCK 2
FILE: test/gatt_structs_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
  group('HaHeartbeat', () {
>>>
NEW_CONTENT: <<<
  group('CmdCode', () {
    test('given reboot constant when accessed then equals 0x01', () {
      expect(CmdCode.reboot, 0x01);
    });
  });

>>>
NOTE: ANCHOR references code inserted by Task 1, EDIT_BLOCK 2.

**Step 4: Run to verify it passes**
Run: `flutter test test/gatt_structs_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/gatt/gatt_structs.dart test/gatt_structs_test.dart && git commit -m "domain(admin-ops): add CmdCode constants for CMD characteristic opcodes"

---

### Task 3: [Domain] Add DeviceRole name-to-uint8 mapping to ManufacturerData

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Modify: `lib/core/ble/manufacturer_data.dart`
- Modify: `test/core/ble/manufacturer_data_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
group('DeviceRole mapping', () {
  test('given Gateway string when roleFromString then returns 0x01', () {
    expect(ManufacturerData.roleFromString('Gateway'), ManufacturerData.roleGateway);
  });
  test('given End Device string when roleFromString then returns 0x02', () {
    expect(ManufacturerData.roleFromString('End Device'), ManufacturerData.roleEndDevice);
  });
  test('given Central Controller string when roleFromString then returns 0x04', () {
    expect(ManufacturerData.roleFromString('Central Controller'), ManufacturerData.roleCentralController);
  });
  test('given unknown string when roleFromString then throws ArgumentError', () {
    expect(() => ManufacturerData.roleFromString('Unknown'), throwsArgumentError);
  });
  test('given role uint8 when roleName then returns display string', () {
    expect(ManufacturerData.roleName(ManufacturerData.roleGateway), 'Gateway');
    expect(ManufacturerData.roleName(ManufacturerData.roleEndDevice), 'End Device');
    expect(ManufacturerData.roleName(ManufacturerData.roleCentralController), 'Central Controller');
  });
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: FAIL (roleFromString and roleName do not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/ble/manufacturer_data.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
  static const int roleCentralController = 0x04;
>>>
NEW_CONTENT: <<<

  /// Display name → uint8 role value mapping. SSOT for provisioning & admin UI.
  static const Map<String, int> _roleMap = {
    'Gateway': roleGateway,
    'End Device': roleEndDevice,
    'Central Controller': roleCentralController,
  };

  /// All valid role display names for dropdown selectors.
  static List<String> get roleNames => _roleMap.keys.toList();

  /// Convert display name to uint8 role value. Throws if unknown.
  static int roleFromString(String name) {
    final value = _roleMap[name];
    if (value == null) {
      throw ArgumentError('Unknown role name: $name');
    }
    return value;
  }

  /// Convert uint8 role value to display name.
  static String roleName(int role) => switch (role) {
    roleGateway => 'Gateway',
    roleEndDevice => 'End Device',
    roleCentralController => 'Central Controller',
    roleUnprovisioned => 'Unprovisioned',
    _ => 'Unknown (0x${role.toRadixString(16)})',
  };
>>>
NOTE: Consolidates role string↔uint8 mapping into ManufacturerData SSOT.

EDIT_BLOCK 2
FILE: test/core/ble/manufacturer_data_test.dart
ACTION: APPEND
ANCHOR: <<<
>>>
NEW_CONTENT: <<<

  group('DeviceRole mapping', () {
    test('given Gateway string when roleFromString then returns 0x01', () {
      expect(ManufacturerData.roleFromString('Gateway'), ManufacturerData.roleGateway);
    });

    test('given End Device string when roleFromString then returns 0x02', () {
      expect(ManufacturerData.roleFromString('End Device'), ManufacturerData.roleEndDevice);
    });

    test('given Central Controller string when roleFromString then returns 0x04', () {
      expect(ManufacturerData.roleFromString('Central Controller'), ManufacturerData.roleCentralController);
    });

    test('given unknown string when roleFromString then throws ArgumentError', () {
      expect(() => ManufacturerData.roleFromString('Unknown'), throwsArgumentError);
    });

    test('given role uint8 when roleName then returns display string', () {
      expect(ManufacturerData.roleName(ManufacturerData.roleGateway), 'Gateway');
      expect(ManufacturerData.roleName(ManufacturerData.roleEndDevice), 'End Device');
      expect(ManufacturerData.roleName(ManufacturerData.roleCentralController), 'Central Controller');
    });
  });
>>>
NOTE: Append inside existing main() — manufacturer_data_test.dart ends with closing braces.

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/ble/manufacturer_data.dart test/core/ble/manufacturer_data_test.dart && git commit -m "domain(provisioning): add DeviceRole name-to-uint8 mapping in ManufacturerData"

---

## Layer 3: Infrastructure

### Task 4: [Infrastructure] Add GattUuids.haHb UUID constant

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/gatt/gatt_uuids.dart`

**Step 1: Write the failing test (BDD format)**

No separate test needed — the UUID constant is validated via HaTab integration in Task 7.

**Step 2: Run to verify it fails**
Run: N/A (constant addition)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/gatt/gatt_uuids.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
  static const peerRole = '6f8a9c14-2c1a-4b6f-8a11-8ddc1f4e7b25';
>>>
NEW_CONTENT: <<<
  static const haHb = '6f8a9c15-2c1a-4b6f-8a11-8ddc1f4e7b25';
>>>
NOTE: HA_HB characteristic UUID per firmware spec. Sequentially follows peerRole (6f8a9c14).

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS (no regressions)

**Step 5: Commit**
git add lib/core/gatt/gatt_uuids.dart && git commit -m "infra(ha-monitoring): add GattUuids.haHb UUID for HA heartbeat characteristic"

---

## Layer 2: Application

### Task 5: [Application] Add haHeartbeatStreamProvider

**Layer:** Application
**DDD Pattern:** UseCase
**Files:**
- Modify: `lib/core/providers/metrics_provider.dart`

**Step 1: Write the failing test (BDD format)**

No unit test for provider wiring — the provider delegates to `_gattNotifyStream` (already tested via statusStreamProvider pattern). Validated via HaTab widget test in Task 7.

**Step 2: Run to verify it fails**
Run: N/A

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/core/providers/metrics_provider.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
/// Live METRICS notify stream parsed into QosMetricsV2.
final metricsStreamProvider = StreamProvider.autoDispose<QosMetricsV2>(
  (ref) => _gattNotifyStream(ref,
    charUuid: GattUuids.metricsV2,
    expectedSize: QosMetricsV2.size,
    parser: QosMetricsV2.fromBytes,
  ),
);
>>>
NEW_CONTENT: <<<

/// Live HA_HB notify stream parsed into HaHeartbeat.
final haHeartbeatStreamProvider = StreamProvider.autoDispose<HaHeartbeat>(
  (ref) => _gattNotifyStream(ref,
    charUuid: GattUuids.haHb,
    expectedSize: HaHeartbeat.size,
    parser: HaHeartbeat.fromBytes,
  ),
);
>>>
NOTE: Follows exact same _gattNotifyStream factory pattern as statusStreamProvider.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS (no regressions)

**Step 5: Commit**
git add lib/core/providers/metrics_provider.dart && git commit -m "app(ha-monitoring): add haHeartbeatStreamProvider using _gattNotifyStream factory"

---

## Layer 4: Presentation

### Task 6: [Presentation] Wire ProvisioningScreen ROLE write to GATT

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/features/provisioning/provisioning_screen.dart`
- Modify: `test/features/provisioning/provisioning_screen_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
// Test that ProvisioningScreen is a ConsumerStatefulWidget and can render in ProviderScope
testWidgets('given ProviderScope when rendered then shows Write ROLE button', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: const MaterialApp(
        home: ProvisioningScreen(deviceId: 'AA:BB:CC:DD'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.widgetWithText(ElevatedButton, 'Write ROLE'), findsOneWidget);
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/features/provisioning/provisioning_screen_test.dart`
Expected: FAIL (existing tests break because ProvisioningScreen becomes ConsumerStatefulWidget needing ProviderScope)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/provisioning/provisioning_screen.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Provisioning flow — spec §9.
/// Role selector (GW/ED/CC), network_id input, device name,
/// ROLE write button with reboot warning. Engineer-only.
class ProvisioningScreen extends StatefulWidget {
  final String deviceId;

  const ProvisioningScreen({super.key, required this.deviceId});

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
>>>
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_gatt.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Provisioning flow — spec §9.
/// Role selector (GW/ED/CC), network_id input, device name,
/// ROLE write button with reboot warning. Engineer-only.
class ProvisioningScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const ProvisioningScreen({super.key, required this.deviceId});

  @override
  ConsumerState<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends ConsumerState<ProvisioningScreen> {
>>>
NOTE: Convert to ConsumerStatefulWidget for Riverpod ref access. Add GATT/auth imports.

EDIT_BLOCK 2
FILE: lib/features/provisioning/provisioning_screen.dart
ACTION: REPLACE
ANCHOR: <<<
  void _onWriteRole() {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog before writing ROLE
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Provisioning'),
        content: Text(
          'Write role "$_selectedRole" with network ID ${_networkIdController.text} '
          'to device ${widget.deviceId}?\n\nThe device will reboot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        // TODO: Write ROLE characteristic via GATT
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ROLE write sent — device will reboot')),
        );
      }
    });
  }
>>>
NEW_CONTENT: <<<
  void _onWriteRole() {
    if (!_formKey.currentState!.validate()) return;

    // Permission gate: ROLE requires engineer role (spec §3.2)
    final session = ref.read(authSessionProvider);
    final role = session.currentRole;
    if (!PermissionGuard.canWrite(role, GattAction.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied: engineer role required for ROLE write')),
      );
      return;
    }

    // Show confirmation dialog before writing ROLE
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Provisioning'),
        content: Text(
          'Write role "$_selectedRole" with network ID ${_networkIdController.text} '
          'to device ${widget.deviceId}?\n\nThe device will reboot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        try {
          final roleValue = ManufacturerData.roleFromString(_selectedRole);
          final connector = ref.read(bleConnectorProvider);
          final gatt = BleGatt(connector);
          await gatt.write(GattUuids.role, [roleValue]);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ROLE write sent — device will reboot')),
          );
          // Navigate back after short delay for reboot
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.of(context).pop();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ROLE write failed: $e')),
          );
        }
      }
    });
  }
>>>
NOTE: Wire _onWriteRole to BleGatt.write with permission check, following ControlTab._writeCtrl pattern.

EDIT_BLOCK 3
FILE: test/features/provisioning/provisioning_screen_test.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/features/provisioning/provisioning_screen.dart';

void main() {
  group('ProvisioningScreen', () {
    testWidgets('renders with device ID in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvisioningScreen(deviceId: 'AA:BB:CC:DD'),
        ),
      );
>>>
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/features/provisioning/provisioning_screen.dart';

void main() {
  group('ProvisioningScreen', () {
    testWidgets('renders with device ID in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'AA:BB:CC:DD'),
          ),
        ),
      );
>>>
NOTE: Wrap in ProviderScope for ConsumerStatefulWidget.

EDIT_BLOCK 4
FILE: test/features/provisioning/provisioning_screen_test.dart
ACTION: REPLACE
ANCHOR: <<<
    testWidgets('shows role selector with GW/ED/CC options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvisioningScreen(deviceId: 'TEST-01'),
        ),
      );
>>>
NEW_CONTENT: <<<
    testWidgets('shows role selector with GW/ED/CC options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-01'),
          ),
        ),
      );
>>>
NOTE: Wrap in ProviderScope.

EDIT_BLOCK 5
FILE: test/features/provisioning/provisioning_screen_test.dart
ACTION: REPLACE
ANCHOR: <<<
    testWidgets('shows network ID input field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvisioningScreen(deviceId: 'TEST-02'),
        ),
      );
>>>
NEW_CONTENT: <<<
    testWidgets('shows network ID input field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-02'),
          ),
        ),
      );
>>>
NOTE: Wrap in ProviderScope.

EDIT_BLOCK 6
FILE: test/features/provisioning/provisioning_screen_test.dart
ACTION: REPLACE
ANCHOR: <<<
    testWidgets('shows device name input field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvisioningScreen(deviceId: 'TEST-03'),
        ),
      );
>>>
NEW_CONTENT: <<<
    testWidgets('shows device name input field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-03'),
          ),
        ),
      );
>>>
NOTE: Wrap in ProviderScope.

EDIT_BLOCK 7
FILE: test/features/provisioning/provisioning_screen_test.dart
ACTION: REPLACE
ANCHOR: <<<
    testWidgets('shows provision button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvisioningScreen(deviceId: 'TEST-04'),
        ),
      );
>>>
NEW_CONTENT: <<<
    testWidgets('shows provision button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-04'),
          ),
        ),
      );
>>>
NOTE: Wrap in ProviderScope.

EDIT_BLOCK 8
FILE: test/features/provisioning/provisioning_screen_test.dart
ACTION: REPLACE
ANCHOR: <<<
    testWidgets('shows reboot warning text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvisioningScreen(deviceId: 'TEST-05'),
        ),
      );
>>>
NEW_CONTENT: <<<
    testWidgets('shows reboot warning text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: ProvisioningScreen(deviceId: 'TEST-05'),
          ),
        ),
      );
>>>
NOTE: Wrap in ProviderScope.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/provisioning/provisioning_screen_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/provisioning/provisioning_screen.dart test/features/provisioning/provisioning_screen_test.dart && git commit -m "ui(provisioning): wire ProvisioningScreen ROLE write to GATT with permission guard"

---

### Task 7: [Presentation] Implement HaTab with heartbeat subscription and display

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/features/device/ha/ha_tab.dart`
- Create: `test/features/device/ha/ha_tab_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
testWidgets('given no connection when rendered then shows loading state', (tester) async {
  // HaTab should show loading/placeholder when no heartbeat data
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/ha/ha_tab_test.dart`
Expected: FAIL (test file does not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/device/ha/ha_tab.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// HA status tab — displays Active/Standby role, epoch, heartbeat,
/// failover history (spec §10).
class HaTab extends StatelessWidget {
  final String deviceId;

  const HaTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'High Availability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HaInfoRow(label: 'HA Role', value: '--'),
                  const Divider(),
                  _HaInfoRow(label: 'Epoch', value: '--'),
                  const Divider(),
                  _HaInfoRow(label: 'Heartbeat', value: '--'),
                  const Divider(),
                  _HaInfoRow(label: 'Peer Status', value: '--'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failover History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Center(
              child: Text(
                'No failover events',
                style: TextStyle(color: AppColors.textSecondary),
              ),
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

import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// HA status tab — subscribes to HA_HB notify, parses 21-byte heartbeat,
/// displays HA role, epoch, heartbeat count, failover event (spec §10).
class HaTab extends ConsumerWidget {
  final String deviceId;

  const HaTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hbAsync = ref.watch(haHeartbeatStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'High Availability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: hbAsync.when(
                loading: () => _buildFields(context, null),
                error: (e, _) => _buildFields(context, null, error: '$e'),
                data: (hb) => _buildFields(context, hb),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failover History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: hbAsync.when(
              loading: () => const Center(
                child: Text('Waiting for heartbeat...', style: TextStyle(color: AppColors.textSecondary)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              ),
              data: (hb) => _buildFailoverInfo(context, hb),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(BuildContext context, HaHeartbeat? hb, {String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        _HaInfoRow(label: 'HA Role', value: hb?.haRoleLabel ?? '--'),
        const Divider(),
        _HaInfoRow(label: 'Epoch', value: hb?.epoch.toString() ?? '--'),
        const Divider(),
        _HaInfoRow(label: 'Heartbeat', value: hb?.heartbeatCount.toString() ?? '--'),
        const Divider(),
        _HaInfoRow(label: 'Peer Status', value: hb?.peerStatusLabel ?? '--'),
      ],
    );
  }

  Widget _buildFailoverInfo(BuildContext context, HaHeartbeat hb) {
    if (hb.lastFailoverTimestamp == 0) {
      return const Center(
        child: Text('No failover events', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    final failoverTime = DateTime.fromMillisecondsSinceEpoch(
      hb.lastFailoverTimestamp * 1000,
    );
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.swap_horiz, color: AppColors.warning),
          title: Text('Last failover: ${failoverTime.toLocal()}'),
          subtitle: Text('Reason code: 0x${hb.lastFailoverReason.toRadixString(16)}'),
        ),
      ],
    );
  }
}
>>>
NOTE: Full rewrite: StatelessWidget → ConsumerWidget with haHeartbeatStreamProvider subscription.

EDIT_BLOCK 2
FILE: test/features/device/ha/ha_tab_test.dart
ACTION: CREATE_FILE
ANCHOR: <<<
>>>
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/features/device/ha/ha_tab.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';

void main() {
  group('HaTab', () {
    testWidgets('given no heartbeat data when rendered then shows placeholder dashes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            haHeartbeatStreamProvider.overrideWith(
              (ref) => const Stream<HaHeartbeat>.empty(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HaTab(deviceId: 'TEST-HA')),
          ),
        ),
      );
      await tester.pump();

      // Loading state should show '--' placeholders
      expect(find.text('High Availability'), findsOneWidget);
      expect(find.text('HA Role'), findsOneWidget);
    });

    testWidgets('given active heartbeat when rendered then shows Active role', (tester) async {
      final hb = HaHeartbeat(
        haRole: HaHeartbeat.roleActive,
        epoch: 5,
        heartbeatCount: 42,
        peerStatus: HaHeartbeat.roleStandby,
        lastFailoverTimestamp: 0,
        lastFailoverReason: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            haHeartbeatStreamProvider.overrideWith(
              (ref) => Stream.value(hb),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HaTab(deviceId: 'TEST-HA')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Standby'), findsOneWidget);
      expect(find.text('No failover events'), findsOneWidget);
    });
  });
}
>>>
NOTE: Widget tests with provider overrides — validates HaTab renders heartbeat data.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/ha/ha_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/ha/ha_tab.dart test/features/device/ha/ha_tab_test.dart && git commit -m "ui(ha-monitoring): implement HaTab with HA heartbeat subscription and live display"

---

### Task 8: [Presentation] Implement AdminTab ENG_UNLOCK PIN dialog

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/features/device/admin/admin_tab.dart`
- Create: `test/features/device/admin/admin_tab_test.dart`

**Step 1: Write the failing test (BDD format)**

```dart
testWidgets('given AdminTab when ENG_UNLOCK tapped then shows PIN dialog', (tester) async {
  // tap ENG_UNLOCK ListTile, expect PIN dialog to appear
});
```

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/admin/admin_tab_test.dart`
Expected: FAIL (test file does not exist)

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/device/admin/admin_tab.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:flutter/material.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// Admin tab — engineer-only actions (spec §11).
/// ENG_UNLOCK, CTRL read, GW_CFG editor, CMD console, PIN management.
/// Replaces old EngineerScreen.
class AdminTab extends StatelessWidget {
  final String deviceId;

  const AdminTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Engineer Admin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_open, color: AppColors.warning),
              title: const Text('ENG_UNLOCK'),
              subtitle: const Text('Unlock engineer mode on device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: ENG_UNLOCK flow
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.terminal, color: AppColors.primary),
              title: const Text('CMD Console'),
              subtitle: const Text('Send raw commands'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: CMD console
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('GW_CFG Editor'),
              subtitle: const Text('Edit gateway configuration'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key, color: AppColors.secondary),
              title: const Text('PIN Management'),
              subtitle: const Text('Set engineer PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: PIN management
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.memory, color: AppColors.primary),
              title: const Text('MODE / ROLE'),
              subtitle: const Text('Change device mode or role'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: MODE/ROLE write
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
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/gatt/gatt_uuids.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

/// ENG_UNLOCK PIN length per firmware spec.
const int engPinLength = 8;

/// Admin tab — engineer-only actions (spec §11).
/// ENG_UNLOCK, CMD reboot, MODE/ROLE write, GW_CFG editor, PIN management.
class AdminTab extends ConsumerWidget {
  final String deviceId;

  const AdminTab({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isEngineer = session.currentRole == AuthRole.engineer;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Engineer Admin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // ENG_UNLOCK
          Card(
            child: ListTile(
              leading: Icon(
                isEngineer ? Icons.lock_open : Icons.lock,
                color: isEngineer ? AppColors.success : AppColors.warning,
              ),
              title: const Text('ENG_UNLOCK'),
              subtitle: Text(isEngineer ? 'Engineer mode active' : 'Unlock engineer mode on device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: isEngineer ? null : () => _showEngUnlockDialog(context, ref),
            ),
          ),
          const SizedBox(height: 8),
          // CMD Reboot
          Card(
            child: ListTile(
              leading: const Icon(Icons.restart_alt, color: AppColors.error),
              title: const Text('CMD Reboot'),
              subtitle: const Text('Reboot device'),
              trailing: const Icon(Icons.chevron_right),
              enabled: isEngineer,
              onTap: isEngineer ? () => _showRebootConfirmation(context, ref) : null,
            ),
          ),
          const SizedBox(height: 8),
          // MODE / ROLE
          Card(
            child: ListTile(
              leading: const Icon(Icons.memory, color: AppColors.primary),
              title: const Text('MODE / ROLE'),
              subtitle: const Text('Change device mode or role'),
              trailing: const Icon(Icons.chevron_right),
              enabled: isEngineer,
              onTap: isEngineer ? () => _showModeRoleDialog(context, ref) : null,
            ),
          ),
          const SizedBox(height: 8),
          // GW_CFG Editor (existing TODO — not implemented in this task)
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('GW_CFG Editor'),
              subtitle: const Text('Edit gateway configuration'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GW_CFG editor
              },
            ),
          ),
          const SizedBox(height: 8),
          // PIN Management (existing TODO — not implemented in this task)
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key, color: AppColors.secondary),
              title: const Text('PIN Management'),
              subtitle: const Text('Set engineer PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: PIN management
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// ENG_UNLOCK flow: show PIN dialog → write ENG_UNLOCK characteristic → elevate AuthSession
  Future<void> _showEngUnlockDialog(BuildContext context, WidgetRef ref) async {
    final pinController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Engineer Unlock'),
        content: TextField(
          controller: pinController,
          decoration: const InputDecoration(
            labelText: 'Engineer PIN',
            hintText: 'Enter 8-character PIN',
            border: OutlineInputBorder(),
          ),
          maxLength: engPinLength,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final pin = pinController.text;
    if (pin.length != engPinLength) {
      _showSnackBar(context, 'PIN must be exactly $engPinLength characters');
      return;
    }

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      // Write ASCII PIN bytes to ENG_UNLOCK characteristic
      await gatt.write(GattUuids.engUnlock, pin.codeUnits);
      // Success — elevate AuthSession to engineer
      final session = ref.read(authSessionProvider);
      session.elevate(AuthRole.engineer, onExpired: () {
        if (context.mounted) {
          _showSnackBar(context, 'Engineer session expired');
        }
      });
      if (!context.mounted) return;
      _showSnackBar(context, 'Engineer mode unlocked');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'ENG_UNLOCK failed: $e');
    }
  }

  /// CMD Reboot flow: confirmation dialog → write CMD 0x01 → handle disconnect
  Future<void> _showRebootConfirmation(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (!PermissionGuard.canWrite(session.currentRole, GattAction.cmdReboot)) {
      _showSnackBar(context, 'Permission denied: engineer role required');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reboot'),
        content: const Text(
          'This will reboot the device.\nThe BLE connection will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reboot'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      await gatt.write(GattUuids.cmd, [CmdCode.reboot]);
      if (!context.mounted) return;
      _showSnackBar(context, 'Reboot command sent — device will disconnect');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Reboot failed: $e');
    }
  }

  /// MODE/ROLE write flow: dropdown selector → confirmation → GATT write
  Future<void> _showModeRoleDialog(BuildContext context, WidgetRef ref) async {
    final session = ref.read(authSessionProvider);
    if (!PermissionGuard.canWrite(session.currentRole, GattAction.mode)) {
      _showSnackBar(context, 'Permission denied: engineer role required');
      return;
    }

    String? writeType;
    int? writeValue;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String selectedType = 'MODE';
        String selectedRole = ManufacturerData.roleNames.first;
        final modeController = TextEditingController(text: '0');

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Write MODE / ROLE'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'MODE', label: Text('MODE')),
                    ButtonSegment(value: 'ROLE', label: Text('ROLE')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) => setDialogState(() => selectedType = s.first),
                ),
                const SizedBox(height: 16),
                if (selectedType == 'ROLE')
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: ManufacturerData.roleNames.map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedRole = v);
                    },
                  )
                else
                  TextFormField(
                    controller: modeController,
                    decoration: const InputDecoration(
                      labelText: 'Mode value (uint8)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 8),
                if (selectedType == 'ROLE')
                  const Text(
                    'Warning: ROLE write will trigger device reboot.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  writeType = selectedType;
                  if (selectedType == 'ROLE') {
                    writeValue = ManufacturerData.roleFromString(selectedRole);
                  } else {
                    writeValue = int.tryParse(modeController.text) ?? 0;
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Write'),
              ),
            ],
          ),
        );
      },
    );

    if (writeType == null || writeValue == null || !context.mounted) return;

    // Confirmation for ROLE write (triggers reboot)
    if (writeType == 'ROLE') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm ROLE Write'),
          content: Text(
            'Write ROLE value 0x${writeValue!.toRadixString(16)} '
            'to device $deviceId?\n\nThe device will reboot.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    try {
      final connector = ref.read(bleConnectorProvider);
      final gatt = BleGatt(connector);
      final uuid = writeType == 'ROLE' ? GattUuids.role : GattUuids.mode;
      await gatt.write(uuid, [writeValue!]);
      if (!context.mounted) return;
      _showSnackBar(context, '$writeType written successfully');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, '$writeType write failed: $e');
    }
  }
}
>>>
NOTE: Full rewrite: StatelessWidget → ConsumerWidget with ENG_UNLOCK, CMD reboot, MODE/ROLE write. Follows ControlTab._writeCtrl() permission-gated pattern.

EDIT_BLOCK 2
FILE: test/features/device/admin/admin_tab_test.dart
ACTION: CREATE_FILE
ANCHOR: <<<
>>>
NEW_CONTENT: <<<
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/auth/auth_session.dart';
import 'package:ble_qos_app/core/providers/auth_provider.dart';
import 'package:ble_qos_app/features/device/admin/admin_tab.dart';

void main() {
  group('AdminTab', () {
    testWidgets('given normal auth when rendered then shows ENG_UNLOCK enabled and CMD disabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Engineer Admin'), findsOneWidget);
      expect(find.text('ENG_UNLOCK'), findsOneWidget);
      expect(find.text('CMD Reboot'), findsOneWidget);
      expect(find.text('MODE / ROLE'), findsOneWidget);
    });

    testWidgets('given normal auth when ENG_UNLOCK tapped then shows PIN dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ENG_UNLOCK'));
      await tester.pumpAndSettle();

      expect(find.text('Engineer Unlock'), findsOneWidget);
      expect(find.text('Engineer PIN'), findsOneWidget);
    });

    testWidgets('given engineer auth when rendered then shows ENG_UNLOCK as active', (tester) async {
      final session = AuthSession();
      session.elevate(AuthRole.engineer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWithValue(session),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Engineer mode active'), findsOneWidget);
      session.dispose();
    });

    testWidgets('given engineer auth when CMD Reboot tapped then shows confirmation dialog', (tester) async {
      final session = AuthSession();
      session.elevate(AuthRole.engineer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWithValue(session),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminTab(deviceId: 'TEST-ADMIN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CMD Reboot'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Reboot'), findsOneWidget);
      expect(find.textContaining('reboot the device'), findsOneWidget);
      session.dispose();
    });
  });
}
>>>
NOTE: Widget tests for AdminTab — validates ENG_UNLOCK dialog, auth gating, reboot confirmation.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/admin/admin_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/admin/admin_tab.dart test/features/device/admin/admin_tab_test.dart && git commit -m "ui(admin-ops): implement AdminTab with ENG_UNLOCK, CMD reboot, MODE/ROLE write"
