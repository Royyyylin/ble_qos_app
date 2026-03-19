import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';

void main() {
  test('Capability equality by id and version', () {
    const a = Capability(id: 'qos_monitor', version: 1);
    const b = Capability(id: 'qos_monitor', version: 1);
    expect(a, equals(b));
  });

  test('Capability inequality on version', () {
    const a = Capability(id: 'qos_monitor', version: 1);
    const b = Capability(id: 'qos_monitor', version: 2);
    expect(a, isNot(equals(b)));
  });
}
