import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Engineer unlock session with 60-second auto-expiry.
/// After expiry, app role drops back to patrol.
class UnlockSession {
  static const duration = Duration(seconds: 60);

  Timer? _timer;
  DateTime? _unlockedAt;
  void Function()? onExpired;

  bool get isUnlocked => _timer?.isActive ?? false;

  Duration get remaining {
    if (_unlockedAt == null || !isUnlocked) return Duration.zero;
    final elapsed = DateTime.now().difference(_unlockedAt!);
    final r = duration - elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  void unlock({void Function()? onExpired}) {
    this.onExpired = onExpired;
    _unlockedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer(duration, _expire);
  }

  void refresh() {
    if (isUnlocked) {
      _unlockedAt = DateTime.now();
      _timer?.cancel();
      _timer = Timer(duration, _expire);
    }
  }

  void lock() {
    _timer?.cancel();
    _timer = null;
    _unlockedAt = null;
  }

  void _expire() {
    _timer = null;
    _unlockedAt = null;
    onExpired?.call();
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Riverpod provider for the unlock session.
final unlockSessionProvider = Provider<UnlockSession>((ref) {
  final session = UnlockSession();
  ref.onDispose(() => session.dispose());
  return session;
});
