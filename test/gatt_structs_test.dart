import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/gatt/gatt_structs.dart';

void main() {
  group('QosStatus', () {
    test('decodes 13-byte STATUS correctly', () {
      // zone=1(MID), profile=2(ROBUST), phy=2(2M), tx=-8, rssi=-55,
      // pdr=95, interval=0x00A0(160), latency=0x0032(50),
      // jitter=0x0005(5), tp=10
      final data = Uint8List.fromList([
        1, 2, 2, 0xF8, 0xC9, // zone, profile, phy, tx(-8), rssi(-55)
        95, 0xA0, 0x00, 0x32, 0x00, // pdr, interval LE, latency LE
        0x05, 0x00, 10, // jitter LE, tp
      ]);
      final s = QosStatus.fromBytes(data);
      expect(s.zone, 1);
      expect(s.profile, 2);
      expect(s.phy, 2);
      expect(s.txPower, -8);
      expect(s.rssi, -55);
      expect(s.pdr, 95);
      expect(s.interval, 160);
      expect(s.latency, 50);
      expect(s.jitter, 5);
      expect(s.tp, 10);
    });

    test('rejects wrong length', () {
      expect(
        () => QosStatus.fromBytes(Uint8List(10)),
        throwsArgumentError,
      );
    });
  });

  group('QosCtrl', () {
    test('decodes 9-byte CTRL correctly', () {
      final data = Uint8List.fromList([
        0, 2, 0x03, 0x50, 0x00, // profile=0, phy=2, tx=3, interval=80 LE
        5, 3, 2, 0x00, // creditA=5, creditC=3, creditR=2, flags=0
      ]);
      final c = QosCtrl.fromBytes(data);
      expect(c.profile, 0);
      expect(c.phy, 2);
      expect(c.txPower, 3);
      expect(c.interval, 80);
      expect(c.creditAlarm, 5);
      expect(c.creditCtrl, 3);
      expect(c.creditRs485, 2);
      expect(c.flags, 0);
    });
  });

  group('QosCtrl.toBytes()', () {
    test('given valid QosCtrl when toBytes then produces 9-byte payload matching fromBytes layout', () {
      final ctrl = QosCtrl(
        profile: 1,
        phy: 2,
        txPower: -4,
        interval: 80,
        creditAlarm: 5,
        creditCtrl: 3,
        creditRs485: 2,
        flags: 0,
      );
      final bytes = ctrl.toBytes();
      expect(bytes.length, QosCtrl.size);
      final decoded = QosCtrl.fromBytes(bytes);
      expect(decoded.profile, 1);
      expect(decoded.phy, 2);
      expect(decoded.txPower, -4);
      expect(decoded.interval, 80);
      expect(decoded.creditAlarm, 5);
      expect(decoded.creditCtrl, 3);
      expect(decoded.creditRs485, 2);
      expect(decoded.flags, 0);
    });

    test('given QosCtrl with negative txPower when toBytes then encodes int8 correctly', () {
      final ctrl = QosCtrl(
        profile: 0, phy: 1, txPower: -20, interval: 160,
        creditAlarm: 0, creditCtrl: 0, creditRs485: 0, flags: 0xFF,
      );
      final bytes = ctrl.toBytes();
      expect(bytes.length, QosCtrl.size);
      final decoded = QosCtrl.fromBytes(bytes);
      expect(decoded.txPower, -20);
      expect(decoded.interval, 160);
      expect(decoded.flags, 0xFF);
    });
  });

  group('QosGwCfgV2', () {
    test('round-trip encode/decode', () {
      final cfg = QosGwCfgV2(
        ver: 2,
        tpMode: 0,
        log: 1,
        flags: 0,
        creditAlarm: 0,
        creditCtrl: 0,
        creditRs485: 5,
        reserved: 0,
      );
      final bytes = cfg.toBytes();
      expect(bytes.length, QosGwCfgV2.size);
      final decoded = QosGwCfgV2.fromBytes(bytes);
      expect(decoded.ver, 2);
      expect(decoded.creditRs485, 5);
    });
  });

  group('QosEvtV1', () {
    test('decodes ALARM event', () {
      final data = Uint8List.fromList([0xE1, 0x01, 0xAA, 0xBB, 0x10, 0x00]);
      final e = QosEvtV1.fromBytes(data);
      expect(e.type, QosEvtV1.typeAlarm);
      expect(e.isAlarm, true);
      expect(e.id, 1);
      expect(e.v0, 0xAA);
      expect(e.v1, 0xBB);
      expect(e.seq, 16);
    });

    test('decodes INFO event', () {
      final data = Uint8List.fromList([0xE2, 0x02, 0x00, 0x00, 0xFF, 0x00]);
      final e = QosEvtV1.fromBytes(data);
      expect(e.isAlarm, false);
      expect(e.seq, 255);
    });
  });

  group('QosPingRsp', () {
    test('decodes 8-byte ping response', () {
      final data = Uint8List(8);
      final bd = ByteData.sublistView(data);
      bd.setUint32(0, 12345, Endian.little);
      bd.setUint32(4, 678, Endian.little);
      final p = QosPingRsp.fromBytes(data);
      expect(p.echoTs, 12345);
      expect(p.rttUs, 678);
    });
  });
}
