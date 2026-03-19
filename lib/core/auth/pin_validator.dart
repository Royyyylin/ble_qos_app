// lib/core/auth/pin_validator.dart
import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;

/// PIN validator with lockout — spec §3.1.
/// Stores hashed PIN, tracks failed attempts.
class PinValidator {
  PinValidator({
    this.maxAttempts = 5,
    this.lockoutDuration = const Duration(minutes: 10),
  });

  final int maxAttempts;
  final Duration lockoutDuration;

  String? _pinHash;
  int _failureCount = 0;
  DateTime? _lockedUntil;

  int get remainingAttempts => maxAttempts - _failureCount;

  bool get isLockedOut {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _failureCount = 0;
      return false;
    }
    return true;
  }

  void setPin(String pin) {
    _pinHash = _hash(pin);
    _failureCount = 0;
    _lockedUntil = null;
  }

  bool get hasPin => _pinHash != null;

  /// Returns true if PIN matches. Returns false if wrong or locked out.
  bool validate(String pin) {
    if (isLockedOut) return false;
    if (_pinHash == null) return false;

    if (_hash(pin) == _pinHash) {
      _failureCount = 0;
      return true;
    }

    _failureCount++;
    if (_failureCount >= maxAttempts) {
      _lockedUntil = DateTime.now().add(lockoutDuration);
    }
    return false;
  }

  static String _hash(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
