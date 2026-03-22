import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';

void main() {
  group('QosMetricsV2', () {
    test('fromBytes parses 20-byte struct correctly', () {
      final data = Uint8List(20);
      final bd = ByteData.sublistView(data);
      bd.setUint16(0, 9850, Endian.little);
      bd.setUint16(2, 12, Endian.little);
      bd.setUint16(4, 3, Endian.little);
      bd.setInt8(6, -55);
      bd.setUint8(7, 1);
      bd.setUint8(8, 2);
      bd.setInt8(9, -4);
      bd.setUint16(10, 1024, Endian.little);
      bd.setUint16(12, 2048, Endian.little);
      bd.setUint16(14, 5, Endian.little);
      bd.setUint16(16, 2, Endian.little);
      bd.setUint16(18, 512, Endian.little);

      final m = QosMetricsV2.fromBytes(data);

      expect(m.pdr, 99);
      expect(m.latency, 12);
      expect(m.jitter, 3);
      expect(m.rssi, -55);
      expect(m.profile, 1);
      expect(m.phy, 2);
      expect(m.txPower, -4);
      expect(m.tpBps, 1024);
      expect(m.tpPeakBps, 2048);
      expect(m.enomemCnt, 5);
      expect(m.eagainCnt, 2);
      expect(m.minStackFree, 512);
    });

    test('fromBytes throws on short data', () {
      expect(() => QosMetricsV2.fromBytes(Uint8List(19)), throwsArgumentError);
    });

    test('fromBytes accepts data longer than 20 bytes', () {
      final data = Uint8List(24);
      final bd = ByteData.sublistView(data);
      bd.setUint16(0, 5000, Endian.little);
      bd.setInt8(6, -70);

      final m = QosMetricsV2.fromBytes(data);
      expect(m.pdr, 50);
      expect(m.rssi, -70);
    });
  });

  group('CmdV2', () {
    test('build creates correct wire format', () {
      final data = CmdV2.build(1, CmdV2Opcode.reboot);
      expect(data, [1, 0x01]);
    });

    test('rosterAdd builds 9-byte payload with LE address', () {
      final data = CmdV2.rosterAdd(42, 'AA:BB:CC:DD:EE:FF');
      expect(data.length, 9); // txn(1) + op(1) + addr_type(1) + addr(6)
      expect(data[0], 42);    // txn_id
      expect(data[1], CmdV2Opcode.rosterAdd);
      expect(data[2], 1);     // addr_type (default random)
      // Address is little-endian: FF:EE:DD:CC:BB:AA
      expect(data[3], 0xFF);
      expect(data[8], 0xAA);
    });

    test('rosterRemove builds 3-byte payload', () {
      final data = CmdV2.rosterRemove(10, 2);
      expect(data, [10, CmdV2Opcode.rosterRemove, 2]);
    });

    test('connectEd builds 9-byte payload', () {
      final data = CmdV2.connectEd(5, '11:22:33:44:55:66');
      expect(data.length, 9);
      expect(data[0], 5);
      expect(data[1], CmdV2Opcode.connectEd);
    });

    test('disconnectEd builds 3-byte payload', () {
      final data = CmdV2.disconnectEd(7, 3);
      expect(data, [7, CmdV2Opcode.disconnectEd, 3]);
    });
  });

  group('CmdResult', () {
    test('fromBytes parses 6-byte struct', () {
      final data = Uint8List.fromList([42, 0x05, 0, 3, 0, 0]);
      final r = CmdResult.fromBytes(data);
      expect(r.txnId, 42);
      expect(r.opcode, CmdV2Opcode.rosterAdd);
      expect(r.status, CmdResultStatus.success);
      expect(r.isSuccess, isTrue);
      expect(r.v0, 3); // logical_slot
    });

    test('fromBytes detects error status', () {
      final data = Uint8List.fromList([1, 0x03, 1, 0x10, 0, 0]);
      final r = CmdResult.fromBytes(data);
      expect(r.isError, isTrue);
      expect(r.v0, 0x10); // error code
    });

    test('fromBytes throws on short data', () {
      expect(() => CmdResult.fromBytes(Uint8List(5)), throwsArgumentError);
    });
  });

  group('RosterEntry', () {
    test('fromBytes parses single 9-byte entry', () {
      // slot=0, addr_type=1(random), addr=AA:BB:CC:DD:EE:FF(LE), state=2(ONLINE)
      final data = Uint8List.fromList([
        0,    // logical_slot
        1,    // addr_type
        0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, // addr LE
        2,    // state = ONLINE
      ]);
      final e = RosterEntry.fromBytes(data);
      expect(e.logicalSlot, 0);
      expect(e.addrType, 1);
      expect(e.address, 'AA:BB:CC:DD:EE:FF');
      expect(e.state, RosterSlotState.online);
      expect(e.isOnline, isTrue);
      expect(e.stateLabel, 'Online');
    });

    test('parseList handles multiple entries including empty', () {
      final data = Uint8List(18); // 2 entries
      // Entry 0: slot=0, empty
      data[0] = 0;
      data[8] = RosterSlotState.empty;
      // Entry 1: slot=1, registered
      data[9] = 1;
      data[10] = 1; // addr_type
      data[17] = RosterSlotState.registered;

      final entries = RosterEntry.parseList(data);
      expect(entries.length, 2);
      expect(entries[0].isEmpty, isTrue);
      expect(entries[1].isRegistered, isTrue);
    });
  });
}
