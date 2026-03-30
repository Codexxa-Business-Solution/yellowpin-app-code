import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../widgets/app_primary_button.dart';

/// Screen 4: Onboarding — "Join the Conversation", pagination dot 3 active, Get Started.
class Onboarding3Page extends StatelessWidget {
  const Onboarding3Page({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(AppAssets.authBackground, fit: BoxFit.cover)),
            Column(
              children: [
                const SizedBox(height: 36),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Image.asset(AppAssets.onboardingGraphic3, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.vertical(top: Radius.elliptical(500, 120)),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.xxl,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Join the Conversation',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingLarge(context).copyWith(fontSize: 42),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Ask questions, share stories,\nand help shape the future of\nHR together.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary, height: 1.35, fontSize: 17),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [_dot(active: false), const SizedBox(width: 10), _dot(active: false), const SizedBox(width: 10), _dot(active: true)],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppPrimaryButton(
                        label: 'Get Started',
                        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.signUpAs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.headerYellow : AppColors.inactiveDot,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
