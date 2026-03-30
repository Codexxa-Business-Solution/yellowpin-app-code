import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';

class ApplicationSuccessPage extends StatelessWidget {
  const ApplicationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};
    final company = (map['company'] ?? 'Force Motors').toString();
    final role = (map['role'] ?? 'Machine Operator').toString();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(top: 4, left: 0, child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryOrange.withValues(alpha: 0.8)))),
                    Positioned(top: 0, right: 8, child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryOrange.withValues(alpha: 0.7)))),
                    Positioned(bottom: 8, right: 0, child: Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryOrange.withValues(alpha: 0.75)))),
                    Positioned(bottom: 4, left: 12, child: Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryOrange.withValues(alpha: 0.65)))),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF8A3D),
                      ),
                      child: const Icon(Icons.check, color: AppColors.white, size: 52),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Congratulation !', style: AppTextStyles.headingLarge(context).copyWith(fontSize: 34)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You\'ve successfully applied to $company $role role.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false, arguments: 0);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAEAEA),
                    side: BorderSide.none,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Find A Similar Job'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 2),
                child: Text('Back To Home', style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.appliedJobDetails, arguments: map),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Track job'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
