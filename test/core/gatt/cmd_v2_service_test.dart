import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';

void main() {
  group('CmdV2', () {
    test('build creates txn_id + opcode header', () {
      final data = CmdV2.build(1, CmdV2Opcode.reboot);
      expect(data.length, 2);
      expect(data[0], 1);  // txn_id
      expect(data[1], 0x01);  // opcode
    });

    test('build with payload appends bytes', () {
      final payload = Uint8List.fromList([0x42]);
      final data = CmdV2.build(5, CmdV2Opcode.disconnectEd, payload);
      expect(data.length, 3);
      expect(data[0], 5);
      expect(data[1], CmdV2Opcode.disconnectEd);
      expect(data[2], 0x42);
    });

    test('rosterAdd builds 9 bytes with LE address', () {
      final data = CmdV2.rosterAdd(10, 'AA:BB:CC:DD:EE:FF');
      expect(data.length, 9);
      expect(data[0], 10);  // txn_id
      expect(data[1], CmdV2Opcode.rosterAdd);
      expect(data[2], 1);  // addr_type (default random)
      // LE address: FF:EE:DD:CC:BB:AA
      expect(data[3], 0xFF);
      expect(data[8], 0xAA);
    });

    test('rosterRemove builds 3 bytes', () {
      final data = CmdV2.rosterRemove(7, 2);
      expect(data.length, 3);
      expect(data[0], 7);
      expect(data[1], CmdV2Opcode.rosterRemove);
      expect(data[2], 2);
    });

    test('connectEd builds 9 bytes', () {
      final data = CmdV2.connectEd(3, '11:22:33:44:55:66', addrType: 0);
      expect(data.length, 9);
      expect(data[0], 3);
      expect(data[1], CmdV2Opcode.connectEd);
      expect(data[2], 0);  // addr_type public
    });

    test('rosterAdd throws on invalid MAC', () {
      expect(
        () => CmdV2.rosterAdd(1, 'invalid'),
        throwsArgumentError,
      );
    });
  });

  group('CmdResult', () {
    test('fromBytes parses success', () {
      final data = Uint8List.fromList([42, 0x05, 0, 3, 0, 0]);
      final r = CmdResult.fromBytes(data);
      expect(r.txnId, 42);
      expect(r.opcode, CmdV2Opcode.rosterAdd);
      expect(r.status, CmdResultStatus.success);
      expect(r.isSuccess, true);
      expect(r.v0, 3);
    });

    test('fromBytes parses error', () {
      final data = Uint8List.fromList([1, 0x06, 1, 0, 0, 0]);
      final r = CmdResult.fromBytes(data);
      expect(r.isError, true);
      expect(r.opcode, CmdV2Opcode.rosterRemove);
    });

    test('fromBytes parses in_progress', () {
      final data = Uint8List.fromList([5, 0x03, 2, 0, 0, 0]);
      final r = CmdResult.fromBytes(data);
      expect(r.status, CmdResultStatus.inProgress);
    });

    test('fromBytes throws on short data', () {
      expect(() => CmdResult.fromBytes(Uint8List(5)), throwsArgumentError);
    });
  });

  group('CmdV2Opcode', () {
    test('constants match ble_api.yaml', () {
      expect(CmdV2Opcode.reboot, 0x01);
      expect(CmdV2Opcode.setMaxEd, 0x02);
      expect(CmdV2Opcode.connectEd, 0x03);
      expect(CmdV2Opcode.disconnectEd, 0x04);
      expect(CmdV2Opcode.rosterAdd, 0x05);
      expect(CmdV2Opcode.rosterRemove, 0x06);
    });
  });

  group('CmdResultStatus', () {
    test('constants match ble_api.yaml', () {
      expect(CmdResultStatus.success, 0);
      expect(CmdResultStatus.error, 1);
      expect(CmdResultStatus.inProgress, 2);
      expect(CmdResultStatus.rejected, 3);
    });
  });
}
