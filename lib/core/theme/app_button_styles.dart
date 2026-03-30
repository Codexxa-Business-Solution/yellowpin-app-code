import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Centralized button styles. Use for ElevatedButton, OutlinedButton, IconButton.
/// Style-only; do not change layout or widget structure.
class AppButtonStyles {
  AppButtonStyles._();

  /// Primary: black background, white text, no elevation, 8px radius.
  static ButtonStyle primary(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      minimumSize: const Size(0, AppSpacing.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      textStyle: AppTextStyles.buttonText(context),
    );
  }

  /// Outline: transparent background, primary text, yellow border.
  static ButtonStyle outline(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.headerYellow),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      minimumSize: const Size(0, AppSpacing.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
    );
  }

  /// Outline small (e.g. View, Create an event pills).
  static ButtonStyle outlineSmall(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.headerYellow),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
    );
  }

  /// Icon button: no background, consistent icon color/size for app bars.
  static ButtonStyle iconAppBar(BuildContext context) {
    return IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      iconSize: 24,
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(40, 40),
    );
  }
}
