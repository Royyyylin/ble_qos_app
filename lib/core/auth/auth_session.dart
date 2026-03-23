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

/// Auth session state — manages role elevation, idle + absolute timeouts.
/// Extends ChangeNotifier so Riverpod widgets rebuild on role changes.
class AuthSession extends ChangeNotifier {
  AuthRole _role = AuthRole.normal;
  Timer? _idleTimer;
  Timer? _absoluteTimer;
  void Function()? _onExpired;
  String? _lastPin; // stored for auto ENG_UNLOCK on reconnect

  AuthRole get currentRole => _role;
  bool get isElevated => _role != AuthRole.normal;

  /// Last PIN used for elevation (for auto GATT ENG_UNLOCK).
  String? get lastPin => _lastPin;

  void elevate(AuthRole role, {String? pin, void Function()? onExpired}) {
    _role = role;
    if (pin != null) _lastPin = pin;
    _onExpired = onExpired;
    _startTimers();
    notifyListeners();
  }

  void demote() {
    _role = AuthRole.normal;
    _cancelTimers();
    notifyListeners();
  }

  void touch() {
    if (!isElevated) return;
    _restartIdleTimer();
  }

  void _startTimers() {
    _cancelTimers();
    if (_role.idleTimeout > Duration.zero) {
      _idleTimer = Timer(_role.idleTimeout, _expire);
    }
    if (_role.absoluteTimeout > Duration.zero) {
      _absoluteTimer = Timer(_role.absoluteTimeout, _expire);
    }
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (_role.idleTimeout > Duration.zero) {
      _idleTimer = Timer(_role.idleTimeout, _expire);
    }
  }

  void _expire() {
    demote();
    _onExpired?.call();
  }

  void _cancelTimers() {
    _idleTimer?.cancel();
    _absoluteTimer?.cancel();
    _idleTimer = null;
    _absoluteTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
