import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/gatt/gatt_structs.dart';

void main() {
  group('QosStatus', () {
    test('decodes 13-byte full STATUS matching firmware struct layout', () {
      // Firmware layout: rssi(int8), pdr_x100(u16LE), lat_ms(u16LE),
      //   jit_ms(u16LE), profile(u8), phy(u8), tx_power(int8),
      //   connected(u8), interval(u16LE)
      final data = Uint8List(13);
      final bd = ByteData.sublistView(data);
      bd.setInt8(0, -55);                    // rssi
      bd.setUint16(1, 9500, Endian.little);  // pdr_x100 = 95.00%
      bd.setUint16(3, 50, Endian.little);    // lat_ms
      bd.setUint16(5, 5, Endian.little);     // jit_ms
      bd.setUint8(7, 2);                     // profile = ROBUST
      bd.setUint8(8, 2);                     // phy = 2M
      bd.setInt8(9, -8);                     // tx_power
      bd.setUint8(10, 1);                    // connected
      bd.setUint16(11, 160, Endian.little);  // interval

      final s = QosStatus.fromBytes(data);
      expect(s.rssi, -55);
      expect(s.pdr, 95); // 9500/100 rounded
      expect(s.latency, 50);
      expect(s.jitter, 5);
      expect(s.profile, 2);
      expect(s.phy, 2);
      expect(s.txPower, -8);
      expect(s.interval, 160);
    });

    test('decodes 4-byte indexed STATUS from GW notify', () {
      // Indexed: ed_idx(u8), flags(u8), tx_power(int8), interval_low(u8)
      // flags: [connected:1][zone:2][profile:2][phy_enc:2][reserved:1]
      // zone=2(FAR), profile=1(BALANCED), phy_enc=1(2M), connected=1
      final flags = 1 | (2 << 1) | (1 << 3) | (1 << 5); // 0b_0_01_01_10_1 = 0x2D
      final data = Uint8List.fromList([3, flags, 0xF8, 80]); // ed=3, tx=-8, interval=80
      final s = QosStatus.fromIndexedBytes(data);
      expect(s.edIndex, 3);
      expect(s.zone, 2);       // FAR
      expect(s.profile, 1);    // BALANCED
      expect(s.phy, 2);        // 2M (enc=1 → phy=2)
      expect(s.txPower, -8);
      expect(s.interval, 80);
    });

    test('parse auto-detects 13-byte full format', () {
      final data = Uint8List(13);
      data[0] = 0xC9; // rssi = -55
      final s = QosStatus.parse(data);
      expect(s.rssi, -55);
    });

    test('parse auto-detects 4-byte indexed format', () {
      final data = Uint8List.fromList([0, 0, 0, 0]);
      final s = QosStatus.parse(data);
      expect(s.edIndex, 0);
    });

    test('rejects data shorter than 4 bytes', () {
      expect(
        () => QosStatus.parse(Uint8List(3)),
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

  group('CmdCode', () {
    test('given reboot constant when accessed then equals 0x01', () {
      expect(CmdCode.reboot, 0x01);
    });
  });

  group('HaHeartbeat', () {
    test('given 21_byte payload when fromBytes then parses all fields correctly', () {
      final data = Uint8List(21);
      final bd = ByteData.sublistView(data);
      bd.setUint8(0, 0x01);                        // haRole = active
      bd.setUint32(1, 42, Endian.little);           // epoch
      bd.setUint32(5, 1000, Endian.little);         // heartbeatCount
      bd.setUint8(9, 0x02);                         // peerStatus = standby
      bd.setUint32(10, 1710000000, Endian.little);  // lastFailoverTimestamp
      bd.setUint8(14, 0x03);                        // lastFailoverReason

      final hb = HaHeartbeat.fromBytes(data);
      expect(hb.haRole, 0x01);
      expect(hb.epoch, 42);
      expect(hb.heartbeatCount, 1000);
      expect(hb.peerStatus, 0x02);
      expect(hb.lastFailoverTimestamp, 1710000000);
      expect(hb.lastFailoverReason, 0x03);
    });

    test('given wrong length when fromBytes then throws ArgumentError', () {
      expect(
        () => HaHeartbeat.fromBytes(Uint8List(10)),
        throwsArgumentError,
      );
    });

    test('given active role when haRoleLabel then returns Active', () {
      final data = Uint8List(21);
      data[0] = 0x01;
      final hb = HaHeartbeat.fromBytes(data);
      expect(hb.haRoleLabel, 'Active');
    });

    test('given standby role when haRoleLabel then returns Standby', () {
      final data = Uint8List(21);
      data[0] = 0x02;
      final hb = HaHeartbeat.fromBytes(data);
      expect(hb.haRoleLabel, 'Standby');
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
