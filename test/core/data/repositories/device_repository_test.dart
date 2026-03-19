import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/data/database.dart';
import 'package:ble_qos_app/core/data/repositories/device_repository.dart';

void main() {
  late AppDatabase db;
  late DeviceRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DeviceRepository(db);
  });

  tearDown(() => db.close());

  group('DeviceRepository', () {
    test('upsertDevice inserts new device', () async {
      await repo.upsertDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'GW-Test',
        role: 'gateway',
        status: 'online',
      );
      final devices = await repo.getAllDevices();
      expect(devices, hasLength(1));
      expect(devices.first.name, 'GW-Test');
    });

    test('upsertDevice updates existing device', () async {
      await repo.upsertDevice(id: 'AA:BB', name: 'Old', role: 'gateway', status: 'online');
      await repo.upsertDevice(id: 'AA:BB', name: 'New', role: 'gateway', status: 'offline');
      final devices = await repo.getAllDevices();
      expect(devices, hasLength(1));
      expect(devices.first.name, 'New');
    });

    test('getDevicesByNetwork filters by networkId', () async {
      await repo.upsertDevice(id: 'A', name: 'A', role: 'ed', status: 'online', networkId: 1);
      await repo.upsertDevice(id: 'B', name: 'B', role: 'ed', status: 'online', networkId: 2);
      final net1 = await repo.getDevicesByNetwork(1);
      expect(net1, hasLength(1));
      expect(net1.first.id, 'A');
    });
  });
}
