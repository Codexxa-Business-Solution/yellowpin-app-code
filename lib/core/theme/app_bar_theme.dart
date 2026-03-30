import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Centralized AppBar styling. Applied via ThemeData.appBarTheme in main.dart.
class AppBarThemeCustom {
  AppBarThemeCustom._();

  static AppBarTheme get theme => AppBarTheme(
        backgroundColor: AppColors.headerYellow,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.headerYellow,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        leadingWidth: 56,
      );

  /// For yellow header bars (e.g. My Jobs, Event list).
  static AppBarTheme get yellowThemeCustom => AppBarTheme(
        backgroundColor: AppColors.headerYellow,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        leadingWidth: 56,
      );
}
