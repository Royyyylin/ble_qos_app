// test/core/auth/pin_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/auth/pin_validator.dart';

void main() {
  group('PinValidator', () {
    late PinValidator validator;

    setUp(() => validator = PinValidator());

    test('validate returns true for correct PIN', () {
      validator.setPin('123456');
      expect(validator.validate('123456'), isTrue);
    });

    test('validate returns false for wrong PIN', () {
      validator.setPin('123456');
      expect(validator.validate('000000'), isFalse);
    });

    test('lockout after 5 failed attempts', () {
      validator.setPin('123456');
      for (var i = 0; i < 5; i++) {
        validator.validate('wrong$i');
      }
      expect(validator.isLockedOut, isTrue);
      expect(validator.validate('123456'), isFalse); // locked out
    });

    test('lockout expires after duration', () async {
      validator = PinValidator(lockoutDuration: Duration(milliseconds: 50));
      validator.setPin('123456');
      for (var i = 0; i < 5; i++) {
        validator.validate('wrong$i');
      }
      expect(validator.isLockedOut, isTrue);
      await Future.delayed(Duration(milliseconds: 60));
      expect(validator.isLockedOut, isFalse);
    });

    test('successful validate resets failure count', () {
      validator.setPin('123456');
      validator.validate('wrong1');
      validator.validate('wrong2');
      validator.validate('123456'); // success resets
      validator.validate('wrong3');
      validator.validate('wrong4');
      validator.validate('wrong5');
      validator.validate('wrong6');
      // 4 failures after reset, not locked out
      expect(validator.isLockedOut, isFalse);
    });

    test('remainingAttempts decreases on failure', () {
      validator.setPin('123456');
      expect(validator.remainingAttempts, 5);
      validator.validate('wrong');
      expect(validator.remainingAttempts, 4);
    });
  });
}
