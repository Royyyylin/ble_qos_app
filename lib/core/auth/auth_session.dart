import 'dart:async';
import 'package:flutter/foundation.dart';

/// Three-tier auth roles — spec §3.1.
enum AuthRole {
  normal,       // Role-0: no auth
  maintenance,  // Role-1: 6-digit PIN (App-side)
  engineer;     // Role-2: 8-digit PIN (firmware ENG_UNLOCK)

  Duration get idleTimeout => switch (this) {
    normal => Duration.zero,
    maintenance => const Duration(minutes: 15),
    engineer => const Duration(minutes: 5),
  };

  Duration get absoluteTimeout => switch (this) {
    normal => Duration.zero,
    maintenance => const Duration(hours: 8),
    engineer => const Duration(hours: 4),
  };
}

/// Warning threshold before session expires.
const _warningThreshold = Duration(seconds: 60);

/// Auth session state — manages role elevation, idle + absolute timeouts.
/// Extends ChangeNotifier so Riverpod widgets rebuild on role changes.
class AuthSession extends ChangeNotifier {
  AuthRole _role = AuthRole.normal;
  Timer? _idleTimer;
  Timer? _absoluteTimer;
  Timer? _warningTimer;
  Timer? _countdownTimer;
  void Function()? _onExpired;
  void Function()? _onWarning;
  String? _lastPin;
  DateTime? _idleExpiresAt;
  int _remainingSeconds = 0;

  AuthRole get currentRole => _role;
  bool get isElevated => _role != AuthRole.normal;
  String? get lastPin => _lastPin;

  /// Seconds remaining before idle timeout. 0 if not elevated.
  int get remainingSeconds => _remainingSeconds;

  /// Whether we're in the warning zone (< 60s remaining).
  bool get isWarning => isElevated && _remainingSeconds > 0 && _remainingSeconds <= _warningThreshold.inSeconds;

  void elevate(AuthRole role, {String? pin, void Function()? onExpired, void Function()? onWarning}) {
    _role = role;
    if (pin != null) _lastPin = pin;
    _onExpired = onExpired;
    _onWarning = onWarning;
    _startTimers();
    notifyListeners();
  }

  void demote() {
    _role = AuthRole.normal;
    _remainingSeconds = 0;
    _idleExpiresAt = null;
    _cancelTimers();
    notifyListeners();
  }

  /// Lock now — immediate demote (for Lock Now button).
  void lockNow() => demote();

  void touch() {
    if (!isElevated) return;
    _restartIdleTimer();
  }

  void _startTimers() {
    _cancelTimers();
    if (_role.idleTimeout > Duration.zero) {
      _idleExpiresAt = DateTime.now().add(_role.idleTimeout);
      _remainingSeconds = _role.idleTimeout.inSeconds;
      _idleTimer = Timer(_role.idleTimeout, _expire);

      // Warning timer: fires when remaining < 60s
      final warningDelay = _role.idleTimeout - _warningThreshold;
      if (warningDelay > Duration.zero) {
        _warningTimer = Timer(warningDelay, () {
          _onWarning?.call();
          _startCountdown();
        });
      } else {
        _startCountdown();
      }
    }
    if (_role.absoluteTimeout > Duration.zero) {
      _absoluteTimer = Timer(_role.absoluteTimeout, _expire);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_idleExpiresAt == null) return;
      _remainingSeconds = _idleExpiresAt!.difference(DateTime.now()).inSeconds;
      if (_remainingSeconds < 0) _remainingSeconds = 0;
      notifyListeners();
    });
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    _countdownTimer?.cancel();
    if (_role.idleTimeout > Duration.zero) {
      _idleExpiresAt = DateTime.now().add(_role.idleTimeout);
      _remainingSeconds = _role.idleTimeout.inSeconds;
      _idleTimer = Timer(_role.idleTimeout, _expire);

      final warningDelay = _role.idleTimeout - _warningThreshold;
      if (warningDelay > Duration.zero) {
        _warningTimer = Timer(warningDelay, () {
          _onWarning?.call();
          _startCountdown();
        });
      }
      notifyListeners();
    }
  }

  void _expire() {
    demote();
    _onExpired?.call();
  }

  void _cancelTimers() {
    _idleTimer?.cancel();
    _absoluteTimer?.cancel();
    _warningTimer?.cancel();
    _countdownTimer?.cancel();
    _idleTimer = null;
    _absoluteTimer = null;
    _warningTimer = null;
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
