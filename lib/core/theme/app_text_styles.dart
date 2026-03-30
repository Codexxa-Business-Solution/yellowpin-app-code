import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design system text styles. Use these only — no hardcoded styles in widgets.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle screenTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );
  }

  static TextStyle headingLarge(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
  }

  static TextStyle headingMedium(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );
  }

  static TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.textPrimary);
  }

  static TextStyle bodyMedium(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textPrimary);
  }

  static TextStyle bodySmall(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textPrimary);
  }

  static TextStyle bodySmallSecondary(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary);
  }

  static TextStyle buttonText(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        );
  }

  static TextStyle link(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.linkBlue,
          decoration: TextDecoration.underline,
        );
  }
}
