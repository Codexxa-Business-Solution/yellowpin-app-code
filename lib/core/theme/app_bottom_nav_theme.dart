import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized bottom navigation styling constants.
/// Use these values in bottom nav bars for consistency (no layout change).
class AppBottomNavTheme {
  AppBottomNavTheme._();

  static const double barHeight = 64.0;
  static const double iconSize = 22.0;
  static const double labelFontSize = 10.0;
  static const Color backgroundColor = AppColors.black;
  static const Color selectedColor = AppColors.headerYellow;
  static const Color unselectedColor = AppColors.navUnselected;

  /// Selected item circle background (e.g. white 20% opacity).
  static Color get selectedIconBackground => AppColors.white.withValues(alpha: 0.2);

  /// Label style for selected tab.
  static TextStyle get labelSelectedStyle => TextStyle(
        color: selectedColor,
        fontSize: labelFontSize,
        fontWeight: FontWeight.w500,
      );

  /// Label style for unselected tab.
  static TextStyle get labelUnselectedStyle => TextStyle(
        color: unselectedColor,
        fontSize: labelFontSize,
      );
}
