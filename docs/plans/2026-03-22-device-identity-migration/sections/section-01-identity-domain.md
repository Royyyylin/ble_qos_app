# Section 1: Device Identity Domain Layer

**Layer:** Domain
**Files Owned:**
- `lib/core/identity/device_identity.dart` (create)
- `lib/core/identity/identity_repository.dart` (create)
- `lib/core/identity/device_identity_service.dart` (create)
- `test/core/identity/device_identity_test.dart` (create)
- `test/core/identity/device_identity_service_test.dart` (create)

**Depends On:** None
**Tasks:** 3 (Task 1, Task 2, Task 3)

---

### Task 1: [Domain] DeviceIdentity Aggregate + StableId Value Object

**Layer:** Domain
**DDD Pattern:** Aggregate + ValueObject
**Files:**
- Create: `lib/core/identity/device_identity.dart`
- Create: `test/core/identity/device_identity_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/identity/device_identity_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/identity/device_identity.dart';

void main() {
  group('DeviceIdentity', () {
    test('given_valid_mac_and_stableId_when_created_then_stores_both', () {
      final identity = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(identity.stableId, '550e8400-e29b-41d4-a716-446655440000');
      expect(identity.mac, 'AA:BB:CC:DD:EE:FF');
    });

    test('given_two_identities_with_same_stableId_when_compared_then_equal', () {
      final a = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      final b = DeviceIdentity(
        stableId: '550e8400-e29b-41d4-a716-446655440000',
        mac: 'AA:BB:CC:DD:EE:FF',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('given_identity_when_toString_then_shows_stableId_and_mac', () {
      final identity = DeviceIdentity(
        stableId: 'abc-123',
        mac: 'AA:BB',
      );
      expect(identity.toString(), contains('abc-123'));
      expect(identity.toString(), contains('AA:BB'));
    });
  });
}
>>>
NOTE: BDD tests for DeviceIdentity aggregate root — stableId/mac mapping.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/identity/device_identity_test.dart`
Expected: FAIL (file not found)

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/identity/device_identity.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
/// DeviceIdentity aggregate — maps a platform MAC to an app-generated StableId (UUIDv4).
/// Invariants:
///   - Each MAC maps to exactly one StableId
///   - StableId is immutable once assigned
///   - MAC-to-StableId mapping is persisted across sessions
class DeviceIdentity {
  /// App-generated UUIDv4 stable identifier — primary key across all 9 touch points.
  final String stableId;

  /// Platform-specific BLE remote identifier (MAC on Android, UUID on iOS).
  /// Used only for FlutterBluePlus operations.
  final String mac;

  /// Timestamp when this identity was first assigned.
  final DateTime createdAt;

  DeviceIdentity({
    required this.stableId,
    required this.mac,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceIdentity &&
          stableId == other.stableId &&
          mac == other.mac;

  @override
  int get hashCode => Object.hash(stableId, mac);

  @override
  String toString() => 'DeviceIdentity(stableId: $stableId, mac: $mac)';
}
>>>
NOTE: Aggregate root for Device Identity bounded context.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/identity/device_identity_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/identity/device_identity.dart test/core/identity/device_identity_test.dart && git commit -m "domain(identity): add DeviceIdentity aggregate with StableId value object"`

---

### Task 2: [Domain] IdentityRepository Interface

**Layer:** Domain
**DDD Pattern:** Repository (interface)
**Files:**
- Create: `lib/core/identity/identity_repository.dart`

**Step 1: Write the failing test (BDD format)**

No test needed for a pure interface — tested via DeviceIdentityService in Task 3.

**Step 2: Skip (interface only)**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/core/identity/identity_repository.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'device_identity.dart';

/// Repository interface for MAC↔StableId persistence.
/// Infrastructure layer provides the Drift-backed implementation.
abstract class IdentityRepository {
  /// Find StableId by MAC address. Returns null if not yet assigned.
  Future<String?> findStableIdByMac(String mac);

  /// Find MAC by StableId. Returns null if unknown.
  Future<String?> findMacByStableId(String stableId);

  /// Persist a new DeviceIdentity mapping.
  Future<void> save(DeviceIdentity identity);

  /// Get all persisted identity mappings (for in-memory cache warm-up).
  Future<List<DeviceIdentity>> getAll();
}
>>>
NOTE: Domain-layer repository interface — no infrastructure dependency.
```

**Step 4: Skip (interface only)**

**Step 5: Commit**
`git add lib/core/identity/identity_repository.dart && git commit -m "domain(identity): add IdentityRepository interface for MAC-StableId persistence"`

---

### Task 3: [Domain] DeviceIdentityService — Resolve or Assign StableId

**Layer:** Domain
**DDD Pattern:** DomainService
**Files:**
- Create: `lib/core/identity/device_identity_service.dart`
- Create: `test/core/identity/device_identity_service_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/identity/device_identity_service_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/identity/device_identity.dart';
import 'package:ble_qos_app/core/identity/device_identity_service.dart';
import 'package:ble_qos_app/core/identity/identity_repository.dart';

/// In-memory mock for IdentityRepository.
class FakeIdentityRepository implements IdentityRepository {
  final _store = <String, DeviceIdentity>{};

  @override
  Future<String?> findStableIdByMac(String mac) async {
    for (final identity in _store.values) {
      if (identity.mac == mac) return identity.stableId;
    }
    return null;
  }

  @override
  Future<String?> findMacByStableId(String stableId) async {
    return _store[stableId]?.mac;
  }

  @override
  Future<void> save(DeviceIdentity identity) async {
    _store[identity.stableId] = identity;
  }

  @override
  Future<List<DeviceIdentity>> getAll() async => _store.values.toList();
}

void main() {
  group('DeviceIdentityService', () {
    late FakeIdentityRepository repo;
    late DeviceIdentityService service;

    setUp(() {
      repo = FakeIdentityRepository();
      service = DeviceIdentityService(repo);
    });

    test('given_new_mac_when_resolveOrAssign_then_generates_stableId_and_persists', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      expect(stableId, isNotEmpty);
      // Should be a UUIDv4 format (8-4-4-4-12)
      expect(stableId.split('-').length, 5);
      // Verify persisted
      final stored = await repo.findStableIdByMac('AA:BB:CC:DD:EE:FF');
      expect(stored, stableId);
    });

    test('given_known_mac_when_resolveOrAssign_then_returns_existing_stableId', () async {
      await service.initialize();
      final first = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      final second = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      expect(second, first);
    });

    test('given_stableId_when_resolveToMac_then_returns_mac', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      final mac = service.resolveToMac(stableId);
      expect(mac, 'AA:BB:CC:DD:EE:FF');
    });

    test('given_unknown_stableId_when_resolveToMac_then_returns_null', () async {
      await service.initialize();
      final mac = service.resolveToMac('unknown-id');
      expect(mac, isNull);
    });

    test('given_cache_populated_when_resolveOrAssignSync_then_returns_from_cache', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB');
      // Sync resolve should work from in-memory cache
      final syncResult = service.resolveOrAssignSync('AA:BB');
      expect(syncResult, stableId);
    });

    test('given_new_mac_when_resolveOrAssignSync_then_generates_and_caches', () async {
      await service.initialize();
      final stableId = service.resolveOrAssignSync('NEW:MAC');
      expect(stableId, isNotEmpty);
      // Second call returns same
      expect(service.resolveOrAssignSync('NEW:MAC'), stableId);
    });
  });
}
>>>
NOTE: Tests for DeviceIdentityService with in-memory fake repository.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/identity/device_identity_service_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/identity/device_identity_service.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

import 'device_identity.dart';
import 'identity_repository.dart';

/// Resolves or assigns StableId (UUIDv4) for BLE devices.
/// Uses an in-memory cache populated at startup to support synchronous
/// resolution in scan callbacks. Async writes persist to IdentityRepository.
class DeviceIdentityService {
  final IdentityRepository _repository;

  /// In-memory cache: MAC → StableId
  final _macToStableId = <String, String>{};

  /// Reverse cache: StableId → MAC
  final _stableIdToMac = <String, String>{};

  DeviceIdentityService(this._repository);

  /// Load all persisted mappings into in-memory cache.
  /// Must be called once at app startup before scan begins.
  Future<void> initialize() async {
    final all = await _repository.getAll();
    for (final identity in all) {
      _macToStableId[identity.mac] = identity.stableId;
      _stableIdToMac[identity.stableId] = identity.mac;
    }
  }

  /// Async resolve: lookup or generate+persist a StableId for [mac].
  Future<String> resolveOrAssign(String mac) async {
    final existing = _macToStableId[mac];
    if (existing != null) return existing;

    final stableId = _generateUuidV4();
    final identity = DeviceIdentity(stableId: stableId, mac: mac);
    _macToStableId[mac] = stableId;
    _stableIdToMac[stableId] = mac;
    await _repository.save(identity);
    return stableId;
  }

  /// Synchronous resolve: lookup from cache or generate+queue persist.
  /// Safe to call from scan callbacks. New mappings are persisted async.
  String resolveOrAssignSync(String mac) {
    final existing = _macToStableId[mac];
    if (existing != null) return existing;

    final stableId = _generateUuidV4();
    final identity = DeviceIdentity(stableId: stableId, mac: mac);
    _macToStableId[mac] = stableId;
    _stableIdToMac[stableId] = mac;
    // Fire-and-forget persist — cache is authoritative
    _repository.save(identity);
    return stableId;
  }

  /// Resolve StableId back to MAC for BLE operations.
  /// Returns null if unknown.
  String? resolveToMac(String stableId) => _stableIdToMac[stableId];

  /// Generate a UUIDv4 string.
  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // Set version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant 10
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
>>>
NOTE: Domain service with in-memory cache for sync scan callback resolution.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/identity/device_identity_service_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/identity/device_identity_service.dart test/core/identity/device_identity_service_test.dart && git commit -m "domain(identity): add DeviceIdentityService with sync cache for scan callbacks"`
