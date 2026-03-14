import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/domain/unlock_session.dart';

void main() {
  group('UnlockSession', () {
    late UnlockSession session;

    setUp(() {
      session = UnlockSession();
    });

    tearDown(() {
      session.dispose();
    });

    test('starts locked', () {
      expect(session.isUnlocked, false);
      expect(session.remaining, Duration.zero);
    });

    test('unlock sets isUnlocked to true', () {
      session.unlock();
      expect(session.isUnlocked, true);
    });

    test('lock returns to locked state', () {
      session.unlock();
      session.lock();
      expect(session.isUnlocked, false);
    });

    test('remaining returns positive duration when unlocked', () {
      session.unlock();
      expect(session.remaining.inSeconds, greaterThan(50));
      expect(session.remaining.inSeconds, lessThanOrEqualTo(60));
    });

    test('refresh resets the timer', () {
      session.unlock();
      session.refresh();
      expect(session.isUnlocked, true);
      expect(session.remaining.inSeconds, greaterThan(55));
    });

    test('refresh does nothing when locked', () {
      session.refresh();
      expect(session.isUnlocked, false);
    });
  });
}
