import 'dart:async';

import 'ble_connector.dart';

/// Auto-reconnect handler for expected disconnections (e.g. ROLE write → reboot).
class BleReconnect {
  BleReconnect(this._connector);

  final BleConnector _connector;
  Timer? _timer;
  int _attempts = 0;
  static const maxAttempts = 5;
  static const retryDelay = Duration(seconds: 3);

  bool get isRetrying => _timer?.isActive ?? false;

  /// Start reconnection loop to the last known device.
  void startReconnect(String deviceId, {void Function()? onGiveUp}) {
    _attempts = 0;
    _tryReconnect(deviceId, onGiveUp);
  }

  void _tryReconnect(String deviceId, void Function()? onGiveUp) {
    if (_attempts >= maxAttempts) {
      cancel();
      onGiveUp?.call();
      return;
    }
    _attempts++;
    _connector.connect(deviceId);

    // Schedule next retry if still disconnected
    _timer = Timer(retryDelay, () {
      if (_connector.state.name == 'disconnected') {
        _tryReconnect(deviceId, onGiveUp);
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
