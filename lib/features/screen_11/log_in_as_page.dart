import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/api/auth_storage.dart';
import '../../widgets/app_primary_button.dart';

/// Screen 11 — choose role, then continue to [SignInPage] with that role.
class LogInAsPage extends StatefulWidget {
  const LogInAsPage({super.key});

  @override
  State<LogInAsPage> createState() => _LogInAsPageState();
}

class _LogInAsPageState extends State<LogInAsPage> {
  int _selectedIndex = 0;

  final List<String> _labels = const ['Individual User', 'Organization', 'Institute'];
  final List<String> _roleValues = const ['job_seeker', 'organisation', 'institute'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialRole = ModalRoute.of(context)?.settings.arguments as String?;
    if (initialRole == null || initialRole.trim().isEmpty) return;
    final normalized = initialRole.trim().toLowerCase();
    final mapped = switch (normalized) {
      'organization' => 'organisation',
      'individual' || 'individual user' || 'individual_user' || 'job seeker' => 'job_seeker',
      _ => normalized,
    };
    final index = _roleValues.indexWhere((r) => r == mapped);
    if (index >= 0) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLastRoleSelection();
  }

  Future<void> _loadLastRoleSelection() async {
    final lastRole = await AuthStorage.getLastLoginRole();
    if (!mounted || lastRole == null || lastRole.trim().isEmpty) return;
    final normalized = lastRole.trim().toLowerCase();
    final mapped = switch (normalized) {
      'organization' => 'organisation',
      'individual user' || 'individual' || 'job seeker' => 'job_seeker',
      _ => normalized,
    };
    final index = _roleValues.indexWhere((r) => r == mapped);
    if (index >= 0) {
      setState(() => _selectedIndex = index);
    }
  }

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
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: MediaQuery.of(context).padding.top + 12,
                color: AppColors.headerYellow,
              ),
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(500, 100)),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 0,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.inputBorder, width: 8),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 20,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.inputBorder, width: 8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.screenHorizontal,
                      right: AppSpacing.screenHorizontal,
                      top: AppSpacing.xl,
                    ),
                    child: Text(
                      'Sign In As',
                      style: AppTextStyles.headingLarge(context).copyWith(fontSize: 44),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Shine professionally!',
                      style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ...List.generate(_labels.length, (i) {
                      final selected = _selectedIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                            onTap: () => setState(() => _selectedIndex = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.headerYellow : AppColors.white,
                                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                                border: Border.all(color: AppColors.headerYellow, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: selected ? AppColors.white : AppColors.scaffoldBackground,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.headerYellow),
                                    ),
                                    child: Icon(
                                      i == 0 ? Icons.person : (i == 1 ? Icons.business : Icons.account_balance),
                                      color: AppColors.textPrimary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: Text(
                                      _labels[i],
                                      style: AppTextStyles.headingMedium(context).copyWith(
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: 'Continue to Form',
                      onPressed: () async {
                        final role = _roleValues[_selectedIndex];
                        await AuthStorage.setSelectedAuthRole(role);
                        await AuthStorage.setLastLoginRole(role);
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, AppRoutes.signIn, arguments: role);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Sign up',
                              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textPrimary),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacementNamed(context, AppRoutes.signUpAs);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
