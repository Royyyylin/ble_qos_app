import 'dart:async';

import 'backoff_config.dart';

/// Auto-reconnect handler using Exponential Backoff for UnexpectedDisconnection.
/// Delay doubles each attempt: baseDelay * 2^attempt, capped at maxDelay.
class BleReconnect {
  BleReconnect({
    required Future<void> Function(String deviceId) connect,
    required bool Function() isDisconnected,
    this.config = const BackoffConfig(),
  })  : _connect = connect,
        _isDisconnected = isDisconnected;

  final Future<void> Function(String deviceId) _connect;
  final bool Function() _isDisconnected;
  final BackoffConfig config;

  Timer? _timer;
  int _attempts = 0;

  bool get isRetrying => _timer?.isActive ?? false;
  int get attemptCount => _attempts;

  /// Start reconnection loop to the last known device using Exponential Backoff.
  void startReconnect(String deviceId, {void Function()? onGiveUp, void Function()? onSuccess}) {
    _attempts = 0;
    _tryReconnect(deviceId, onGiveUp: onGiveUp, onSuccess: onSuccess);
  }

  Future<void> _tryReconnect(
    String deviceId, {
    void Function()? onGiveUp,
    void Function()? onSuccess,
  }) async {
    if (_attempts >= config.maxAttempts) {
      cancel();
      onGiveUp?.call();
      return;
    }

    _attempts++;
    try {
      await _connect(deviceId);
      // ReconnectSucceeded — reset and notify
      _timer?.cancel();
      _timer = null;
      onSuccess?.call();
      return;
    } catch (_) {
      // Connection failed — schedule next attempt with Exponential Backoff
    }

    final delay = config.delayForAttempt(_attempts - 1);
    _timer = Timer(delay, () {
      if (_isDisconnected()) {
        _tryReconnect(deviceId, onGiveUp: onGiveUp, onSuccess: onSuccess);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _attempts = 0;
  }

  void dispose() {
    cancel();
  }
}
