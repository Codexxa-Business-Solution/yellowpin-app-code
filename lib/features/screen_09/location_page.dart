import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Let's confirm your location", style: AppTextStyles.headingLarge(context).copyWith(fontSize: 24)),
              const SizedBox(height: AppSpacing.sm),
              Text('Get noticed by recruiters in your area.', style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(label: null, hint: 'City'),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: null, hint: 'State'),
              const SizedBox(height: AppSpacing.xxl),
              AppPrimaryButton(label: 'Register', onPressed: () => Navigator.pushNamed(context, AppRoutes.details)),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
