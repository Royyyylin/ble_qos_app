/// Exponential Backoff configuration for BleReconnect.
/// delay = min(baseDelay * 2^attempt, maxDelay)
class BackoffConfig {
  final Duration baseDelay;
  final Duration maxDelay;
  final int maxAttempts;

  const BackoffConfig({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 32),
    this.maxAttempts = 5,
  });

  /// Calculate delay for a given attempt number (0-indexed).
  Duration delayForAttempt(int attempt) {
    final delayMs = baseDelay.inMilliseconds * (1 << attempt);
    final cappedMs = delayMs.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedMs);
  }
}
