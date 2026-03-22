import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../ble/ble_gatt.dart';
import 'gatt_structs.dart';
import 'gatt_uuids.dart';

/// Manages CMD_V2 writes and correlates CMD_RESULT responses by txn_id.
class CmdV2Service {
  final BleGatt _gatt;
  int _nextTxnId = 1;
  StreamSubscription<Uint8List>? _resultSub;
  final _pending = <int, Completer<CmdResult>>{};

  CmdV2Service(this._gatt);

  /// Start listening for CMD_RESULT notifications.
  Future<void> startListening() async {
    try {
      final stream = await _gatt.subscribe(GattUuids.cmdResult);
      _resultSub = stream.listen((data) {
        if (data.length < CmdResult.size) return;
        final result = CmdResult.fromBytes(data);
        debugPrint('[CMD_V2] result txn=${result.txnId} op=0x${result.opcode.toRadixString(16)} status=${result.status}');
        final completer = _pending.remove(result.txnId);
        completer?.complete(result);
      });
    } catch (e) {
      debugPrint('[CMD_V2] subscribe CMD_RESULT failed: $e');
    }
  }

  /// Send a CMD_V2 command and wait for the matching CMD_RESULT.
  /// Returns null on timeout (default 10s).
  Future<CmdResult?> send(
    int opcode, [
    Uint8List? payload,
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    final txnId = _nextTxnId;
    _nextTxnId = (_nextTxnId % 255) + 1; // 1-255, wraps

    final completer = Completer<CmdResult>();
    _pending[txnId] = completer;

    try {
      final wire = CmdV2.build(txnId, opcode, payload);
      await _gatt.write(GattUuids.cmdV2, wire);
      debugPrint('[CMD_V2] sent txn=$txnId op=0x${opcode.toRadixString(16)}');
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _pending.remove(txnId);
      debugPrint('[CMD_V2] timeout txn=$txnId');
      return null;
    } catch (e) {
      _pending.remove(txnId);
      debugPrint('[CMD_V2] error txn=$txnId: $e');
      rethrow;
    }
  }

  /// Convenience: ROSTER_ADD command.
  Future<CmdResult?> rosterAdd(String macAddress, {int addrType = 1}) async {
    final parts = macAddress.split(':');
    if (parts.length != 6) throw ArgumentError('Invalid MAC: $macAddress');
    final payload = Uint8List(7);
    payload[0] = addrType;
    for (int i = 0; i < 6; i++) {
      payload[1 + (5 - i)] = int.parse(parts[i], radix: 16);
    }
    return send(CmdV2Opcode.rosterAdd, payload);
  }

  /// Convenience: ROSTER_REMOVE command.
  Future<CmdResult?> rosterRemove(int logicalSlot) {
    return send(CmdV2Opcode.rosterRemove, Uint8List.fromList([logicalSlot]));
  }

  void dispose() {
    _resultSub?.cancel();
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('CmdV2Service disposed'));
      }
    }
    _pending.clear();
  }
}
