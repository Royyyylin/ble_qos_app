import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/domain/health_threshold.dart';

void main() {
  group('HealthThreshold.rssi', () {
    test('> -65 is PASS', () => expect(HealthThreshold.rssi(-40), HealthLevel.pass));
    test('-65 is WARNING', () => expect(HealthThreshold.rssi(-65), HealthLevel.warning));
    test('-85 is WARNING', () => expect(HealthThreshold.rssi(-85), HealthLevel.warning));
    test('< -85 is FAIL', () => expect(HealthThreshold.rssi(-90), HealthLevel.fail));
  });

  group('HealthThreshold.pdr', () {
    test('> 95 is PASS', () => expect(HealthThreshold.pdr(99), HealthLevel.pass));
    test('95 is WARNING', () => expect(HealthThreshold.pdr(95), HealthLevel.warning));
    test('85 is WARNING', () => expect(HealthThreshold.pdr(85), HealthLevel.warning));
    test('< 85 is FAIL', () => expect(HealthThreshold.pdr(80), HealthLevel.fail));
  });

  group('HealthThreshold.latency', () {
    test('< 20 is PASS', () => expect(HealthThreshold.latency(10), HealthLevel.pass));
    test('20 is WARNING', () => expect(HealthThreshold.latency(20), HealthLevel.warning));
    test('50 is WARNING', () => expect(HealthThreshold.latency(50), HealthLevel.warning));
    test('> 50 is FAIL', () => expect(HealthThreshold.latency(60), HealthLevel.fail));
  });

  group('HealthThreshold.jitter', () {
    test('< 5 is PASS', () => expect(HealthThreshold.jitter(3), HealthLevel.pass));
    test('5 is WARNING', () => expect(HealthThreshold.jitter(5), HealthLevel.warning));
    test('15 is WARNING', () => expect(HealthThreshold.jitter(15), HealthLevel.warning));
    test('> 15 is FAIL', () => expect(HealthThreshold.jitter(20), HealthLevel.fail));
  });
}
