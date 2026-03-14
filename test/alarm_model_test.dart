import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/domain/alarm_model.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';

void main() {
  group('AlarmHistory', () {
    late AlarmHistory history;

    setUp(() {
      history = AlarmHistory(maxEntries: 5);
    });

    QosEvtV1 makeEvt(int type, int id) {
      return QosEvtV1.fromBytes(
        Uint8List.fromList([type, id, 0, 0, 0, 0]),
      );
    }

    test('adds events and maintains order (newest first)', () {
      history.add(makeEvt(0xE1, 1));
      history.add(makeEvt(0xE2, 2));
      expect(history.entries.length, 2);
      expect(history.entries.first.evt.id, 2); // newest
    });

    test('respects maxEntries', () {
      for (var i = 0; i < 10; i++) {
        history.add(makeEvt(0xE1, i));
      }
      expect(history.entries.length, 5);
    });

    test('acknowledge marks entry', () {
      history.add(makeEvt(0xE1, 1));
      expect(history.unacknowledgedCount, 1);
      history.acknowledge(0);
      expect(history.unacknowledgedCount, 0);
    });

    test('acknowledgeAll marks all entries', () {
      history.add(makeEvt(0xE1, 1));
      history.add(makeEvt(0xE1, 2));
      history.acknowledgeAll();
      expect(history.unacknowledgedCount, 0);
    });

    test('addNote stores note', () {
      history.add(makeEvt(0xE1, 1));
      history.addNote(0, 'test note');
      expect(history.entries.first.note, 'test note');
    });

    test('alarmCount counts only ALARM type', () {
      history.add(makeEvt(0xE1, 1)); // ALARM
      history.add(makeEvt(0xE2, 2)); // INFO
      history.add(makeEvt(0xE1, 3)); // ALARM
      expect(history.alarmCount, 2);
    });
  });
}
