import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/backoff_config.dart';

void main() {
  group('BackoffConfig', () {
    test('given_default_BackoffConfig_when_created_then_has_correct_defaults', () {
      const config = BackoffConfig();
      expect(config.baseDelay, const Duration(seconds: 1));
      expect(config.maxDelay, const Duration(seconds: 32));
      expect(config.maxAttempts, 5);
    });

    test('given_BackoffConfig_when_delayForAttempt_called_then_doubles_each_attempt', () {
      const config = BackoffConfig();
      expect(config.delayForAttempt(0), const Duration(seconds: 1));
      expect(config.delayForAttempt(1), const Duration(seconds: 2));
      expect(config.delayForAttempt(2), const Duration(seconds: 4));
      expect(config.delayForAttempt(3), const Duration(seconds: 8));
      expect(config.delayForAttempt(4), const Duration(seconds: 16));
      expect(config.delayForAttempt(5), const Duration(seconds: 32));
    });

    test('given_BackoffConfig_when_delayForAttempt_exceeds_max_then_caps_at_maxDelay', () {
      const config = BackoffConfig();
      expect(config.delayForAttempt(10), const Duration(seconds: 32));
    });

    test('given_custom_BackoffConfig_when_created_then_uses_custom_values', () {
      const config = BackoffConfig(
        baseDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 16),
        maxAttempts: 3,
      );
      expect(config.baseDelay, const Duration(seconds: 2));
      expect(config.maxDelay, const Duration(seconds: 16));
      expect(config.maxAttempts, 3);
      expect(config.delayForAttempt(0), const Duration(seconds: 2));
      expect(config.delayForAttempt(1), const Duration(seconds: 4));
      expect(config.delayForAttempt(5), const Duration(seconds: 16)); // capped
    });
  });
}
