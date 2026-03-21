import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/backoff_config.dart';
import 'package:ble_qos_app/core/ble/ble_reconnect.dart';

void main() {
  group('BleReconnect', () {
    test('given_default_config_when_created_then_is_not_retrying', () {
      final reconnect = BleReconnect(
        connect: (_) async {},
        isDisconnected: () => true,
      );
      expect(reconnect.isRetrying, isFalse);
      expect(reconnect.attemptCount, 0);
      reconnect.dispose();
    });

    test('given_custom_backoff_config_when_created_then_uses_custom_config', () {
      const config = BackoffConfig(
        baseDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 8),
        maxAttempts: 3,
      );
      final reconnect = BleReconnect(
        connect: (_) async {},
        isDisconnected: () => true,
        config: config,
      );
      expect(reconnect.config.maxAttempts, 3);
      expect(reconnect.config.baseDelay, const Duration(seconds: 2));
      reconnect.dispose();
    });

    test('given_ble_reconnect_when_cancel_called_then_resets_attempts', () {
      final reconnect = BleReconnect(
        connect: (_) async {},
        isDisconnected: () => true,
      );
      reconnect.startReconnect('test-device');
      reconnect.cancel();
      expect(reconnect.isRetrying, isFalse);
      expect(reconnect.attemptCount, 0);
      reconnect.dispose();
    });
  });
}
