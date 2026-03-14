import 'dart:collection';

import '../gatt/gatt_structs.dart';

/// Alarm history entry with timestamp and optional user note.
class AlarmEntry {
  final QosEvtV1 evt;
  final DateTime timestamp;
  String? note;
  bool acknowledged;

  AlarmEntry({
    required this.evt,
    DateTime? timestamp,
    this.note,
    this.acknowledged = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isAlarm => evt.isAlarm;
}

/// In-memory alarm history buffer (most recent first).
/// Future: back with SQLite via drift.
class AlarmHistory {
  AlarmHistory({this.maxEntries = 200});

  final int maxEntries;
  final _entries = Queue<AlarmEntry>();

  List<AlarmEntry> get entries => _entries.toList();
  List<AlarmEntry> get unacknowledged =>
      _entries.where((e) => !e.acknowledged).toList();
  int get alarmCount => _entries.where((e) => e.isAlarm).length;
  int get unacknowledgedCount => unacknowledged.length;

  void add(QosEvtV1 evt) {
    _entries.addFirst(AlarmEntry(evt: evt));
    while (_entries.length > maxEntries) {
      _entries.removeLast();
    }
  }

  void acknowledge(int index) {
    final list = _entries.toList();
    if (index >= 0 && index < list.length) {
      list[index].acknowledged = true;
    }
  }

  void acknowledgeAll() {
    for (final e in _entries) {
      e.acknowledged = true;
    }
  }

  void addNote(int index, String note) {
    final list = _entries.toList();
    if (index >= 0 && index < list.length) {
      list[index].note = note;
    }
  }

  void clear() => _entries.clear();
}
