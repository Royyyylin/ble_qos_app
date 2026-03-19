import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

void main() {
  test('AppColors.background is Deep Navy #0A0E1A', () {
    expect(AppColors.background.value, 0xFF0A0E1A);
  });
  test('AppColors.primary is Electric Cyan #00E5FF', () {
    expect(AppColors.primary.value, 0xFF00E5FF);
  });
  test('AppColors.surface is Dark Slate #141B2D', () {
    expect(AppColors.surface.value, 0xFF141B2D);
  });
  test('AppColors.error is Signal Red #FF1744', () {
    expect(AppColors.error.value, 0xFFFF1744);
  });
  test('AppColors.success is Neon Green #00E676', () {
    expect(AppColors.success.value, 0xFF00E676);
  });
  test('AppColors.warning is Amber Orange #FF6B35', () {
    expect(AppColors.warning.value, 0xFFFF6B35);
  });
}
