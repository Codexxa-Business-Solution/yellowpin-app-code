import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';

/// Shown after institute taps **Campus Confirm** — success state with next steps.
class CampusConfirmationSentPage extends StatelessWidget {
  const CampusConfirmationSentPage({super.key});

  static const List<({double dx, double dy, double size})> _confetti = [
    (dx: 0, dy: 8, size: 5),
    (dx: 112, dy: 4, size: 7),
    (dx: 124, dy: 48, size: 4),
    (dx: 8, dy: 52, size: 6),
    (dx: 20, dy: 96, size: 5),
    (dx: 108, dy: 100, size: 6),
    (dx: 56, dy: 0, size: 4),
    (dx: 72, dy: 118, size: 5),
  ];

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
    final jobTitle = (map['jobTitle'] ?? 'Campus Drive for Designer').toString();

    void goHome() {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
        arguments: 2,
      );
    }

    void interviewSteps() {
      final jid = map['jobId'];
      final jobId = jid is int ? jid : int.tryParse('$jid');
      Navigator.pushNamed(
        context,
        AppRoutes.interviewSteps,
        arguments: <String, dynamic>{
          'jobId': jobId,
          'jobTitle': jobTitle,
          'students': map['students'],
          'stepIndex': 0,
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8D5B0).withValues(alpha: 0.45), width: 1.5),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8D5B0).withValues(alpha: 0.35), width: 1.5),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final p in _confetti)
                          Positioned(
                            left: p.dx,
                            top: p.dy,
                            child: Container(
                              width: p.size,
                              height: p.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryOrange.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF8A3D),
                            ),
                            child: const Icon(Icons.check, color: AppColors.white, size: 46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Campus Confirmation Sent',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingLarge(context).copyWith(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Your campus confirmation has been successfully shared with the company. They will review it and proceed with the next steps.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: goHome,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8E8E8),
                              side: BorderSide.none,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: goHome,
                          child: Text(
                            'Back To Home',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: interviewSteps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Interview Steps', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
