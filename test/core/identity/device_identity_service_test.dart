import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/identity/device_identity.dart';
import 'package:ble_qos_app/core/identity/device_identity_service.dart';
import 'package:ble_qos_app/core/identity/identity_repository.dart';

/// In-memory mock for IdentityRepository.
class FakeIdentityRepository implements IdentityRepository {
  final _store = <String, DeviceIdentity>{};
  final _aliases = <String, String>{};

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

  @override
  Future<void> setAlias(String stableId, String? alias) async {
    if (alias != null && alias.isNotEmpty) {
      _aliases[stableId] = alias;
    } else {
      _aliases.remove(stableId);
    }
  }

  @override
  Future<String?> getAlias(String stableId) async => _aliases[stableId];

  @override
  Future<Map<String, String>> getAllAliases() async => Map.of(_aliases);
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

    test('given_stableId_when_setAlias_then_getAlias_returns_it', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      await service.setAlias(stableId, '3F-會議室-GW');
      expect(service.getAlias(stableId), '3F-會議室-GW');
    });

    test('given_alias_set_when_setAlias_null_then_alias_cleared', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      await service.setAlias(stableId, 'MyDevice');
      await service.setAlias(stableId, null);
      expect(service.getAlias(stableId), isNull);
    });

    test('given_aliases_persisted_when_initialize_then_cache_populated', () async {
      await service.initialize();
      final stableId = await service.resolveOrAssign('AA:BB:CC:DD:EE:FF');
      await service.setAlias(stableId, 'Persisted-Alias');

      // Create new service instance pointing to same repo
      final service2 = DeviceIdentityService(repo);
      await service2.initialize();
      expect(service2.getAlias(stableId), 'Persisted-Alias');
    });

    test('getAllAliases returns all cached aliases', () async {
      await service.initialize();
      final id1 = await service.resolveOrAssign('AA:BB');
      final id2 = await service.resolveOrAssign('CC:DD');
      await service.setAlias(id1, 'Device-A');
      await service.setAlias(id2, 'Device-B');
      final all = service.getAllAliases();
      expect(all[id1], 'Device-A');
      expect(all[id2], 'Device-B');
    });
  });
}
