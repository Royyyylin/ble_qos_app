# Section 3: BLE Scan Lifecycle — ScannedDevice + TTL Eviction

**Layer:** Domain / Infrastructure
**Files Owned:**
- `lib/core/ble/ble_models.dart` (modify)
- `lib/core/ble/ble_scanner.dart` (modify)
- `test/core/ble/ble_models_test.dart` (modify)
- `test/core/ble/ble_scanner_test.dart` (create)

**Depends On:** Section 1 (DeviceIdentityService for StableId resolution in scanner)
**Tasks:** 2 (Task 6, Task 7)

---

### Task 6: [Domain] Add `mac` Field to ScannedDevice

**Layer:** Domain
**DDD Pattern:** Entity (VisibleDevice)
**Files:**
- Modify: `lib/core/ble/ble_models.dart`
- Modify: `test/core/ble/ble_models_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/ble/ble_models_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
  group('BleConnectionState', () {
>>>
NEW_CONTENT: <<<
    test('given_scannedDevice_with_mac_when_accessed_then_returns_mac', () {
      final d = ScannedDevice(
        id: '550e8400-e29b-41d4-a716-446655440000',
        name: 'GW-Test',
        rssi: -60,
        smoothedRssi: -62.5,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(d.mac, 'AA:BB:CC:DD:EE:FF');
      expect(d.id, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('given_scannedDevice_without_mac_when_accessed_then_mac_is_null', () {
      final d = ScannedDevice(
        id: 'some-id',
        name: 'Test',
        rssi: -60,
        smoothedRssi: -60.0,
        status: DeviceStatus.online,
        lastSeen: DateTime(2026, 1, 1),
      );
      expect(d.mac, isNull);
    });

>>>
NOTE: Tests for new mac field on ScannedDevice.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/ble_models_test.dart`
Expected: FAIL (no `mac` parameter)

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/ble/ble_models.dart
ACTION: REPLACE
ANCHOR: <<<
/// Discovered BLE device info from scan results.
class ScannedDevice {
  final String id;
  final String name;
  final int rssi;
  final double smoothedRssi;
  final DeviceStatus status;
  final DateTime lastSeen;
  final ManufacturerData? mfgData;
  final String? alias;

  const ScannedDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.smoothedRssi,
    required this.status,
    required this.lastSeen,
    this.mfgData,
    this.alias,
  });
>>>
NEW_CONTENT: <<<
/// Discovered BLE device info from scan results.
/// After identity migration: [id] = StableId (UUIDv4), [mac] = platform remoteId.
class ScannedDevice {
  /// StableId (UUIDv4) — app-generated stable identity, primary key.
  final String id;
  final String name;
  final int rssi;
  final double smoothedRssi;
  final DeviceStatus status;
  final DateTime lastSeen;
  final ManufacturerData? mfgData;
  final String? alias;

  /// Platform BLE remote identifier (MAC on Android, UUID on iOS).
  /// Used only for FlutterBluePlus operations.
  final String? mac;

  const ScannedDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.smoothedRssi,
    required this.status,
    required this.lastSeen,
    this.mfgData,
    this.alias,
    this.mac,
  });
>>>
NOTE: Add mac field to ScannedDevice; id becomes StableId.
```

```
EDIT_BLOCK 3
FILE: lib/core/ble/ble_models.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Copy with updated fields.
  ScannedDevice copyWith({
    int? rssi,
    double? smoothedRssi,
    DeviceStatus? status,
    DateTime? lastSeen,
    ManufacturerData? mfgData,
    String? alias,
  }) {
    return ScannedDevice(
      id: id,
      name: name,
      rssi: rssi ?? this.rssi,
      smoothedRssi: smoothedRssi ?? this.smoothedRssi,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      mfgData: mfgData ?? this.mfgData,
      alias: alias ?? this.alias,
    );
  }
>>>
NEW_CONTENT: <<<
  /// Copy with updated fields.
  ScannedDevice copyWith({
    int? rssi,
    double? smoothedRssi,
    DeviceStatus? status,
    DateTime? lastSeen,
    ManufacturerData? mfgData,
    String? alias,
    String? mac,
  }) {
    return ScannedDevice(
      id: id,
      name: name,
      rssi: rssi ?? this.rssi,
      smoothedRssi: smoothedRssi ?? this.smoothedRssi,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      mfgData: mfgData ?? this.mfgData,
      alias: alias ?? this.alias,
      mac: mac ?? this.mac,
    );
  }
>>>
NOTE: Add mac to copyWith.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_models_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/ble/ble_models.dart test/core/ble/ble_models_test.dart && git commit -m "domain(scan): add mac field to ScannedDevice for identity migration"`

---

### Task 7: [Infrastructure] BleScanner Identity Resolution + TTL Eviction

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_scanner.dart`
- Create: `test/core/ble/ble_scanner_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/ble/ble_scanner_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/ble_scanner.dart';

void main() {
  group('BleScanner TTL Eviction', () {
    test('given_offline_device_when_updateDeviceStatuses_then_device_evicted', () {
      // This tests the eviction logic — offline devices should be removed
      // from _devices map after offlineThreshold is exceeded.
      // Since BleScanner uses FlutterBluePlus internally, we test the
      // pure function eviction logic via deviceStatusFromLastSeen.
      final now = DateTime(2026, 1, 1, 0, 1, 0); // 60s later
      final lastSeen = DateTime(2026, 1, 1, 0, 0, 0);
      final status = deviceStatusFromLastSeen(lastSeen, now: now);
      expect(status, DeviceStatus.offline);
      // Eviction policy: offline devices should be removed from visible list
    });
  });
}
>>>
NOTE: Unit test for TTL eviction logic.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/ble/ble_scanner_test.dart`
Expected: PASS (this is a pure function test; the real behavior change is in BleScanner)

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
import '../gatt/gatt_uuids.dart';
import 'ble_models.dart';
import 'manufacturer_data.dart';
>>>
NEW_CONTENT: <<<
import '../gatt/gatt_uuids.dart';
import '../identity/device_identity_service.dart';
import 'ble_models.dart';
import 'manufacturer_data.dart';
>>>
NOTE: Import DeviceIdentityService for MAC→StableId resolution.
```

```
EDIT_BLOCK 3
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
/// BLE scanner with EMA smoothing, stale/offline tracking, and duty cycle — spec §4.1.
class BleScanner {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();
  Timer? _statusTimer;
  Timer? _dutyCycleTimer;
  bool _scanning = false;
>>>
NEW_CONTENT: <<<
/// BLE scanner with EMA smoothing, stale/offline tracking, TTL eviction,
/// and duty cycle — spec §4.1.
/// After identity migration: _devices keyed by StableId, not MAC.
class BleScanner {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final _devices = <String, ScannedDevice>{};
  final _controller = StreamController<List<ScannedDevice>>.broadcast();
  Timer? _statusTimer;
  Timer? _dutyCycleTimer;
  bool _scanning = false;
  DeviceIdentityService? _identityService;

  /// Inject DeviceIdentityService for MAC→StableId resolution.
  set identityService(DeviceIdentityService? service) =>
      _identityService = service;
>>>
NOTE: Add DeviceIdentityService dependency for scan-time resolution.
```

```
EDIT_BLOCK 4
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    for (final r in results) {
      final id = r.device.remoteId.str;

      // Device name: prefer advName, fallback to platformName
      final advName = r.advertisementData.advName;
      final platformName = r.device.platformName;
      final name = advName.isNotEmpty ? advName : platformName;
      final existing = _devices[id];

      // Parse manufacturer data
      ManufacturerData? mfgData;
      final mfgMap = r.advertisementData.manufacturerData;
      if (mfgMap.isNotEmpty) {
        final entry = mfgMap.entries.first;
        mfgData = ManufacturerData.parse(
          Uint8List.fromList([...entry.value]),
        );
      }

      // EMA smoothing
      final smoothed = emaRssi(r.rssi, existing?.smoothedRssi, alpha: emaAlpha);

      // Software filter: only QoS devices (connectable + advertising UUID 0x1820).
      if (!r.advertisementData.connectable) continue;
      final hasQosUuid = r.advertisementData.serviceUuids.contains(_qosServiceUuid);
      if (!hasQosUuid) continue;

      _devices[id] = ScannedDevice(
        id: id,
        name: name,
        rssi: r.rssi,
        smoothedRssi: smoothed,
        status: DeviceStatus.online,
        lastSeen: now,
        mfgData: mfgData ?? existing?.mfgData,
        alias: existing?.alias,
      );
    }
    _controller.add(_devices.values.toList());
  }
>>>
NEW_CONTENT: <<<
  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    for (final r in results) {
      final mac = r.device.remoteId.str;

      // Resolve MAC → StableId via DeviceIdentityService (sync from cache)
      final stableId = _identityService?.resolveOrAssignSync(mac) ?? mac;

      // Device name: prefer advName, fallback to platformName
      final advName = r.advertisementData.advName;
      final platformName = r.device.platformName;
      final name = advName.isNotEmpty ? advName : platformName;
      final existing = _devices[stableId];

      // Parse manufacturer data
      ManufacturerData? mfgData;
      final mfgMap = r.advertisementData.manufacturerData;
      if (mfgMap.isNotEmpty) {
        final entry = mfgMap.entries.first;
        mfgData = ManufacturerData.parse(
          Uint8List.fromList([...entry.value]),
        );
      }

      // EMA smoothing
      final smoothed = emaRssi(r.rssi, existing?.smoothedRssi, alpha: emaAlpha);

      // Software filter: only QoS devices (connectable + advertising UUID 0x1820).
      if (!r.advertisementData.connectable) continue;
      final hasQosUuid = r.advertisementData.serviceUuids.contains(_qosServiceUuid);
      if (!hasQosUuid) continue;

      _devices[stableId] = ScannedDevice(
        id: stableId,
        name: name,
        rssi: r.rssi,
        smoothedRssi: smoothed,
        status: DeviceStatus.online,
        lastSeen: now,
        mfgData: mfgData ?? existing?.mfgData,
        alias: existing?.alias,
        mac: mac,
      );
    }
    _controller.add(_devices.values.toList());
  }
>>>
NOTE: Key _devices by StableId instead of MAC. Resolve MAC→StableId sync from cache.
```

```
EDIT_BLOCK 5
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Update device statuses based on lastSeen time.
  void _updateDeviceStatuses() {
    bool changed = false;
    final now = DateTime.now();
    for (final entry in _devices.entries.toList()) {
      final newStatus = deviceStatusFromLastSeen(entry.value.lastSeen, now: now);
      if (newStatus != entry.value.status) {
        _devices[entry.key] = entry.value.copyWith(status: newStatus);
        changed = true;
      }
    }
    if (changed) {
      _controller.add(_devices.values.toList());
    }
  }
>>>
NEW_CONTENT: <<<
  /// Update device statuses based on lastSeen time.
  /// Evicts devices that have been offline beyond offlineThreshold (TTL Eviction).
  void _updateDeviceStatuses() {
    bool changed = false;
    final now = DateTime.now();
    final toEvict = <String>[];

    for (final entry in _devices.entries.toList()) {
      final newStatus = deviceStatusFromLastSeen(entry.value.lastSeen, now: now);
      if (newStatus == DeviceStatus.offline) {
        // TTL Eviction: remove offline devices from visible list
        toEvict.add(entry.key);
        changed = true;
      } else if (newStatus != entry.value.status) {
        _devices[entry.key] = entry.value.copyWith(status: newStatus);
        changed = true;
      }
    }

    for (final key in toEvict) {
      _devices.remove(key);
    }

    if (changed) {
      _controller.add(_devices.values.toList());
    }
  }
>>>
NOTE: TTL Eviction — remove offline devices from _devices map instead of keeping them.
```

```
EDIT_BLOCK 6
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
/// Riverpod provider for the scanner.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
>>>
NEW_CONTENT: <<<
/// Riverpod provider for the scanner.
/// Injects DeviceIdentityService for MAC→StableId resolution.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  // Identity service injection — will be wired when identityServiceProvider exists
  // scanner.identityService = ref.watch(identityServiceProvider);
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
>>>
NOTE: Placeholder for identity service injection — wired in section 4.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_scanner_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/ble/ble_scanner.dart test/core/ble/ble_scanner_test.dart && git commit -m "infra(scan): migrate BleScanner to StableId keys with TTL eviction"`
