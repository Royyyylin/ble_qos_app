import 'dart:ui';

import '../theme/app_colors.dart';

/// Health judgment result for a single metric.
enum HealthLevel { pass, warning, fail, unknown }

/// APP-side Pass/Fail thresholds. GW sends raw values only.
/// Source: UI_REDESIGN_SPEC.md §Thresholds
class HealthThreshold {
  HealthThreshold._();

  static HealthLevel rssi(int value) {
    if (value > -65) return HealthLevel.pass;
    if (value >= -85) return HealthLevel.warning;
    return HealthLevel.fail;
  }

  static HealthLevel pdr(int value) {
    if (value > 95) return HealthLevel.pass;
    if (value >= 85) return HealthLevel.warning;
    return HealthLevel.fail;
  }

  static HealthLevel latency(int value) {
    if (value < 20) return HealthLevel.pass;
    if (value <= 50) return HealthLevel.warning;
    return HealthLevel.fail;
  }

  static HealthLevel jitter(int value) {
    if (value < 5) return HealthLevel.pass;
    if (value <= 15) return HealthLevel.warning;
    return HealthLevel.fail;
  }

  /// Get color for a health level.
  static Color colorFor(HealthLevel level) => switch (level) {
        HealthLevel.pass => AppColors.success,
        HealthLevel.warning => AppColors.warning,
        HealthLevel.fail => AppColors.error,
        HealthLevel.unknown => AppColors.primary,
      };
}
