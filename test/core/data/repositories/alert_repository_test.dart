import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/data/database.dart';
import 'package:ble_qos_app/core/data/repositories/alert_repository.dart';

void main() {
  late AppDatabase db;
  late AlertRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AlertRepository(db);
  });
  tearDown(() => db.close());

  test('insertAlert and getUnresolved', () async {
    await repo.insertAlert(deviceId: 'A', severity: 'warning', type: 'weak_signal', message: 'RSSI -85');
    final alerts = await repo.getUnresolved();
    expect(alerts, hasLength(1));
    expect(alerts.first.type, 'weak_signal');
  });

  test('acknowledge marks alert', () async {
    await repo.insertAlert(deviceId: 'A', severity: 'critical', type: 'offline');
    final alerts = await repo.getUnresolved();
    await repo.acknowledge(alerts.first.id);
    final after = await repo.getUnresolved();
    expect(after, isEmpty);
  });
}
