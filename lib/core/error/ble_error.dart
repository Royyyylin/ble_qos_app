/// BLE error taxonomy — spec §4 (foundations/04-timeout-error.md).
/// 7 categories with retry policy.
enum BleErrorType {
  permissionDenied,     // BT/location permission not granted
  bluetoothOff,         // Bluetooth adapter disabled
  deviceBusy,           // Device already connected / busy
  timeout,              // connect / discover / handshake / capability timeout
  outOfRange,           // RSSI too weak or device not found
  gattFailure,          // GATT read/write/subscribe error
  unexpectedDisconnect, // Connection lost unexpectedly
}

/// Whether this error type is retryable.
extension BleErrorRetry on BleErrorType {
  bool get isRetryable => switch (this) {
    BleErrorType.permissionDenied => false,
    BleErrorType.bluetoothOff => false,
    BleErrorType.deviceBusy => true,
    BleErrorType.timeout => true,
    BleErrorType.outOfRange => true,
    BleErrorType.gattFailure => true,
    BleErrorType.unexpectedDisconnect => true,
  };

  int get maxRetries => switch (this) {
    BleErrorType.deviceBusy => 3,
    BleErrorType.timeout => 3,
    BleErrorType.outOfRange => 2,
    BleErrorType.gattFailure => 3,
    BleErrorType.unexpectedDisconnect => 3,
    _ => 0,
  };

  String get userMessage => switch (this) {
    BleErrorType.permissionDenied => 'Bluetooth permission required. Please enable in Settings.',
    BleErrorType.bluetoothOff => 'Bluetooth is turned off. Please enable Bluetooth.',
    BleErrorType.deviceBusy => 'Device is busy. Retrying...',
    BleErrorType.timeout => 'Connection timed out. Please try again.',
    BleErrorType.outOfRange => 'Device out of range. Move closer and try again.',
    BleErrorType.gattFailure => 'Communication error. Please try again.',
    BleErrorType.unexpectedDisconnect => 'Device disconnected unexpectedly.',
  };
}

/// Structured BLE error with classification.
class BleError {
  final BleErrorType type;
  final String? detail;
  final Object? cause;

  const BleError(this.type, {this.detail, this.cause});

  bool get isRetryable => type.isRetryable;
  String get userMessage => type.userMessage;

  /// Classify a platform exception into a BleErrorType.
  static BleErrorType classify(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('permission')) return BleErrorType.permissionDenied;
    if (msg.contains('bluetooth') && msg.contains('off') ||
        msg.contains('adapter') && msg.contains('not')) {
      return BleErrorType.bluetoothOff;
    }
    if (msg.contains('busy') || msg.contains('already connected')) {
      return BleErrorType.deviceBusy;
    }
    if (msg.contains('timeout')) return BleErrorType.timeout;
    if (msg.contains('out of range') || msg.contains('not found')) {
      return BleErrorType.outOfRange;
    }
    if (msg.contains('disconnect')) return BleErrorType.unexpectedDisconnect;
    return BleErrorType.gattFailure;
  }

  @override
  String toString() => 'BleError($type${detail != null ? ': $detail' : ''})';
}
