import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/data/database.dart';
import 'package:ble_qos_app/core/data/repositories/audit_repository.dart';

void main() {
  late AppDatabase db;
  late AuditRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AuditRepository(db);
  });
  tearDown(() => db.close());

  test('log and retrieve audit entries', () async {
    await repo.log(userRole: 'Role-1', action: 'write_ctrl', targetDevice: 'GW-1');
    final entries = await repo.getAll();
    expect(entries, hasLength(1));
    expect(entries.first.action, 'write_ctrl');
  });

  test('getByRole filters entries', () async {
    await repo.log(userRole: 'Role-1', action: 'a');
    await repo.log(userRole: 'Role-2', action: 'b');
    final r1 = await repo.getByRole('Role-1');
    expect(r1, hasLength(1));
  });
}
