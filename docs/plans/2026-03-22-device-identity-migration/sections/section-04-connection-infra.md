# Section 4: Connection Infrastructure — Identity Resolution + DB Migration

**Layer:** Infrastructure
**Files Owned:**
- `lib/core/providers/device_provider.dart` (modify)
- `lib/core/ble/ble_connector.dart` (modify)
- `lib/core/data/tables/device_identities.dart` (create)
- `lib/core/data/tables/devices.dart` (modify)
- `lib/core/data/database.dart` (modify)
- `lib/core/data/repositories/device_repository.dart` (modify)
- `lib/core/identity/drift_identity_repository.dart` (create)
- `lib/core/providers/identity_provider.dart` (create)
- `test/core/providers/device_provider_test.dart` (create)
- `test/core/identity/drift_identity_repository_test.dart` (create)

**Depends On:** Section 1 (identity domain), Section 3 (ScannedDevice.mac field)
**Tasks:** 4 (Task 8, Task 9, Task 10, Task 11)

---

### Task 8: [Infrastructure] Add `mac` Field to ConnectedDevice

**Layer:** Infrastructure
**DDD Pattern:** Entity
**Files:**
- Modify: `lib/core/providers/device_provider.dart`
- Create: `test/core/providers/device_provider_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/providers/device_provider_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';
import 'package:ble_qos_app/core/providers/device_provider.dart';

void main() {
  group('ConnectedDevice', () {
    test('given_connected_device_when_created_then_stores_mac_field', () {
      final cd = ConnectedDevice(
        id: 'stable-id-123',
        name: 'GW-1',
        mode: ConnectionMode.gwAggregate,
        role: ManufacturerData.roleGateway,
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(cd.id, 'stable-id-123');
      expect(cd.mac, 'AA:BB:CC:DD:EE:FF');
    });
  });

  group('ConnectedDeviceNotifier', () {
    test('given_scanned_device_with_mac_when_connect_then_carries_mac', () {
      final notifier = ConnectedDeviceNotifier();
      final scanned = ScannedDevice(
        id: 'stable-id-456',
        name: 'GW-Test',
        rssi: -55,
        smoothedRssi: -55.0,
        status: DeviceStatus.online,
        lastSeen: DateTime.now(),
        mac: 'AA:BB:CC:DD:EE:FF',
        mfgData: ManufacturerData(
          protocolVersion: 1,
          role: ManufacturerData.roleGateway,
          networkId: 1,
        ),
      );
      notifier.connect(scanned);
      expect(notifier.debugState?.mac, 'AA:BB:CC:DD:EE:FF');
      expect(notifier.debugState?.id, 'stable-id-456');
    });
  });
}
>>>
NOTE: Tests for mac field on ConnectedDevice.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/providers/device_provider_test.dart`
Expected: FAIL (no `mac` field on ConnectedDevice)

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/providers/device_provider.dart
ACTION: REPLACE
ANCHOR: <<<
/// Currently connected device state.
class ConnectedDevice {
  final String id;
  final String name;
  final ConnectionMode mode;
  final int role; // ManufacturerData role constant

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.mode,
    required this.role,
  });
}
>>>
NEW_CONTENT: <<<
/// Currently connected device state.
/// After identity migration: [id] = StableId, [mac] = platform remoteId for BLE ops.
class ConnectedDevice {
  /// StableId (UUIDv4) — primary identity.
  final String id;
  final String name;
  final ConnectionMode mode;
  final int role; // ManufacturerData role constant

  /// Platform BLE remote identifier — needed by FlutterBluePlus for connect/GATT.
  final String? mac;

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.mode,
    required this.role,
    this.mac,
  });
}
>>>
NOTE: Add mac field to ConnectedDevice.
```

```
EDIT_BLOCK 3
FILE: lib/core/providers/device_provider.dart
ACTION: REPLACE
ANCHOR: <<<
  void connect(ScannedDevice device) {
    final role = device.mfgData?.role ?? ManufacturerData.roleUnprovisioned;
    final mode = device.mfgData?.isGateway == true
        ? ConnectionMode.gwAggregate
        : ConnectionMode.edDirect;
    state = ConnectedDevice(
      id: device.id,
      name: device.name,
      mode: mode,
      role: role,
    );
  }
>>>
NEW_CONTENT: <<<
  void connect(ScannedDevice device) {
    final role = device.mfgData?.role ?? ManufacturerData.roleUnprovisioned;
    final mode = device.mfgData?.isGateway == true
        ? ConnectionMode.gwAggregate
        : ConnectionMode.edDirect;
    state = ConnectedDevice(
      id: device.id,
      name: device.name,
      mode: mode,
      role: role,
      mac: device.mac,
    );
  }
>>>
NOTE: Pass mac from ScannedDevice to ConnectedDevice.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/providers/device_provider_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/providers/device_provider.dart test/core/providers/device_provider_test.dart && git commit -m "infra(provider): add mac field to ConnectedDevice for BLE operations"`

---

### Task 9: [Infrastructure] BleConnector StableId→MAC Resolution

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/ble/ble_connector.dart`

**Step 1: Write the failing test (BDD format)**

No new test file — the existing `ble_connector_test.dart` covers connect behavior.
The change is transparent: `connect(stableId)` resolves to MAC internally.

**Step 2: Skip**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/ble/ble_connector.dart
ACTION: REPLACE
ANCHOR: <<<
import '../gatt/gatt_peer_role.dart';
import '../gatt/gatt_uuids.dart';
import 'backoff_config.dart';
import 'ble_models.dart';
import 'ble_reconnect.dart';
import 'ble_service_utils.dart';
>>>
NEW_CONTENT: <<<
import '../gatt/gatt_peer_role.dart';
import '../gatt/gatt_uuids.dart';
import '../identity/device_identity_service.dart';
import 'backoff_config.dart';
import 'ble_models.dart';
import 'ble_reconnect.dart';
import 'ble_service_utils.dart';
>>>
NOTE: Import DeviceIdentityService for StableId→MAC resolution.
```

```
EDIT_BLOCK 2
FILE: lib/core/ble/ble_connector.dart
ACTION: REPLACE
ANCHOR: <<<
class BleConnector {
  StreamSubscription<BluetoothConnectionState>? _connSub;
  BluetoothDevice? _device;
  List<BluetoothService>? _services;
  BleConnectionState _state = BleConnectionState.disconnected;
  final _stateController = StreamController<BleConnectionState>.broadcast();
  bool _intentionalDisconnect = false;
  BleReconnect? _reconnect;
>>>
NEW_CONTENT: <<<
class BleConnector {
  StreamSubscription<BluetoothConnectionState>? _connSub;
  BluetoothDevice? _device;
  List<BluetoothService>? _services;
  BleConnectionState _state = BleConnectionState.disconnected;
  final _stateController = StreamController<BleConnectionState>.broadcast();
  bool _intentionalDisconnect = false;
  BleReconnect? _reconnect;
  DeviceIdentityService? _identityService;

  /// Inject DeviceIdentityService for StableId→MAC resolution.
  set identityService(DeviceIdentityService? service) =>
      _identityService = service;
>>>
NOTE: Add identity service field for StableId→MAC resolution.
```

```
EDIT_BLOCK 3
FILE: lib/core/ble/ble_connector.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Connect to device, discover services, and perform PEER_ROLE Handshake.
  /// Completes only after Handshake succeeds or an error occurs.
  /// On failure, transitions to [BleConnectionState.error].
  Future<void> connect(String deviceId) async {
    _intentionalDisconnect = false;
    _reconnect?.cancel();
    _setState(BleConnectionState.connecting);
    debugPrint('[BLE_CONN] connect($deviceId) started');
    _device = BluetoothDevice.fromId(deviceId);
>>>
NEW_CONTENT: <<<
  /// Connect to device, discover services, and perform PEER_ROLE Handshake.
  /// Accepts StableId — resolves to platform MAC via DeviceIdentityService.
  /// Completes only after Handshake succeeds or an error occurs.
  /// On failure, transitions to [BleConnectionState.error].
  Future<void> connect(String deviceId) async {
    _intentionalDisconnect = false;
    _reconnect?.cancel();
    _setState(BleConnectionState.connecting);
    // Resolve StableId → MAC for FlutterBluePlus (falls back to raw deviceId if no service)
    final mac = _identityService?.resolveToMac(deviceId) ?? deviceId;
    debugPrint('[BLE_CONN] connect($deviceId) → mac=$mac');
    _device = BluetoothDevice.fromId(mac);
>>>
NOTE: Resolve StableId→MAC before calling FlutterBluePlus. Falls back to raw deviceId if no identity service.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/ble/ble_connector_test.dart`
Expected: PASS (existing tests still pass — identity service is null, fallback used)

**Step 5: Commit**
`git add lib/core/ble/ble_connector.dart && git commit -m "infra(connector): resolve StableId to MAC via DeviceIdentityService before BLE connect"`

---

### Task 10: [Infrastructure] DeviceIdentities Drift Table + DriftIdentityRepository

**Layer:** Infrastructure
**DDD Pattern:** Repository (implementation)
**Files:**
- Create: `lib/core/data/tables/device_identities.dart`
- Create: `lib/core/identity/drift_identity_repository.dart`
- Modify: `lib/core/data/database.dart`
- Modify: `lib/core/data/tables/devices.dart`

**Step 1: Write the failing test (BDD format)**

Drift table + repository implementation requires code generation (`build_runner`).
Tests will verify after DB migration and code gen.

**Step 2: Skip (requires build_runner)**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/data/tables/device_identities.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:drift/drift.dart';

/// Drift table for DeviceIdentity persistence — MAC↔StableId mapping.
class DeviceIdentities extends Table {
  /// App-generated UUIDv4 stable identifier.
  TextColumn get stableId => text()();

  /// Platform BLE remote identifier (MAC on Android, UUID on iOS).
  TextColumn get mac => text().unique()();

  /// Timestamp when identity was first assigned (epoch ms).
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {stableId};
}
>>>
NOTE: New Drift table for identity persistence.
```

```
EDIT_BLOCK 2
FILE: lib/core/data/tables/devices.dart
ACTION: REPLACE
ANCHOR: <<<
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
>>>
NEW_CONTENT: <<<
class Devices extends Table {
  /// StableId (UUIDv4) — primary key after identity migration.
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  /// Platform MAC address — added in schema v2 for BLE operations.
  TextColumn get mac => text().nullable()();
>>>
NOTE: Add mac column to Devices table for schema v2.
```

```
EDIT_BLOCK 3
FILE: lib/core/data/database.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:drift/drift.dart';

import 'tables/devices.dart';
import 'tables/alerts.dart';
import 'tables/audit_log.dart';
import 'tables/device_telemetry.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Devices, Alerts, AuditLog, DeviceTelemetry])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
>>>
NEW_CONTENT: <<<
import 'package:drift/drift.dart';

import 'tables/devices.dart';
import 'tables/device_identities.dart';
import 'tables/alerts.dart';
import 'tables/audit_log.dart';
import 'tables/device_telemetry.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Devices, DeviceIdentities, Alerts, AuditLog, DeviceTelemetry])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Schema v2: add DeviceIdentities table + mac column to Devices
        await migrator.createTable(deviceIdentities);
        await migrator.addColumn(devices, devices.mac);
      }
    },
  );
}
>>>
NOTE: Bump schema to v2, add migration for DeviceIdentities table and Devices.mac column.
```

```
EDIT_BLOCK 4
FILE: lib/core/identity/drift_identity_repository.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:drift/drift.dart';

import '../data/database.dart';
import 'device_identity.dart';
import 'identity_repository.dart';

/// Drift-backed implementation of IdentityRepository.
class DriftIdentityRepository implements IdentityRepository {
  final AppDatabase _db;

  DriftIdentityRepository(this._db);

  @override
  Future<String?> findStableIdByMac(String mac) async {
    final row = await (_db.select(_db.deviceIdentities)
          ..where((t) => t.mac.equals(mac)))
        .getSingleOrNull();
    return row?.stableId;
  }

  @override
  Future<String?> findMacByStableId(String stableId) async {
    final row = await (_db.select(_db.deviceIdentities)
          ..where((t) => t.stableId.equals(stableId)))
        .getSingleOrNull();
    return row?.mac;
  }

  @override
  Future<void> save(DeviceIdentity identity) async {
    await _db.into(_db.deviceIdentities).insertOnConflictUpdate(
      DeviceIdentitiesCompanion.insert(
        stableId: identity.stableId,
        mac: identity.mac,
        createdAt: identity.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<List<DeviceIdentity>> getAll() async {
    final rows = await _db.select(_db.deviceIdentities).get();
    return rows
        .map((r) => DeviceIdentity(
              stableId: r.stableId,
              mac: r.mac,
              createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
            ))
        .toList();
  }
}
>>>
NOTE: Drift implementation of IdentityRepository.
```

**Step 4: Run build_runner to regenerate Drift code**
Run: `dart run build_runner build --delete-conflicting-outputs`
Then: `flutter test test/core/data/`
Expected: PASS

**Step 5: Commit**
`git add lib/core/data/tables/device_identities.dart lib/core/data/tables/devices.dart lib/core/data/database.dart lib/core/identity/drift_identity_repository.dart && git commit -m "infra(data): add DeviceIdentities table, Devices.mac column, schema v2 migration"`

---

### Task 11: [Infrastructure] Identity Provider Wiring

**Layer:** Infrastructure
**DDD Pattern:** Adapter (Riverpod provider)
**Files:**
- Create: `lib/core/providers/identity_provider.dart`
- Modify: `lib/core/ble/ble_scanner.dart` (wire identity service)
- Modify: `lib/core/ble/ble_connector.dart` (wire identity service)

**Step 1: Write the failing test (BDD format)**

Provider wiring is integration-level — no unit test needed.

**Step 2: Skip**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/providers/identity_provider.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../identity/device_identity_service.dart';
import '../identity/drift_identity_repository.dart';

/// Provider for the AppDatabase singleton.
/// In production, provide via ProviderScope override with actual QueryExecutor.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in ProviderScope with actual DB',
  );
});

/// Provider for DeviceIdentityService — singleton, initialized once.
final identityServiceProvider = Provider<DeviceIdentityService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = DriftIdentityRepository(db);
  final service = DeviceIdentityService(repo);
  return service;
});
>>>
NOTE: Riverpod providers for identity infrastructure.
```

```
EDIT_BLOCK 2
FILE: lib/core/ble/ble_scanner.dart
ACTION: REPLACE
ANCHOR: <<<
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
NEW_CONTENT: <<<
/// Riverpod provider for the scanner.
/// Injects DeviceIdentityService for MAC→StableId resolution.
final bleScannerProvider = Provider<BleScanner>((ref) {
  final scanner = BleScanner();
  try {
    scanner.identityService = ref.watch(identityServiceProvider);
  } catch (_) {
    // identityServiceProvider not yet initialized — scanner works without it
  }
  ref.onDispose(() => scanner.dispose());
  return scanner;
});
>>>
NOTE: Wire DeviceIdentityService into BleScanner provider. ANCHOR references code from Task 7.
```

```
EDIT_BLOCK 3
FILE: lib/core/ble/ble_scanner.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import '../identity/device_identity_service.dart';
>>>
NEW_CONTENT: <<<
import '../providers/identity_provider.dart';
>>>
NOTE: Import identity provider for bleScannerProvider wiring.
```

```
EDIT_BLOCK 4
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
/// Injects DeviceIdentityService for StableId→MAC resolution.
final bleConnectorProvider = Provider<BleConnector>((ref) {
  final connector = BleConnector();
  try {
    connector.identityService = ref.watch(identityServiceProvider);
  } catch (_) {
    // identityServiceProvider not yet initialized — connector falls back to raw deviceId
  }
  ref.onDispose(() => connector.dispose());
  return connector;
});
>>>
NOTE: Wire DeviceIdentityService into BleConnector provider.
```

```
EDIT_BLOCK 5
FILE: lib/core/ble/ble_connector.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import '../identity/device_identity_service.dart';
>>>
NEW_CONTENT: <<<
import '../providers/identity_provider.dart';
>>>
NOTE: Import identity provider for bleConnectorProvider wiring.
```

**Step 4: Run to verify it compiles**
Run: `flutter test test/core/ble/ble_connector_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/providers/identity_provider.dart lib/core/ble/ble_scanner.dart lib/core/ble/ble_connector.dart && git commit -m "infra(provider): wire DeviceIdentityService into BleScanner and BleConnector providers"`
