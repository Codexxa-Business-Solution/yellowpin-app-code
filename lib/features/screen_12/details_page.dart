import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';

/// Screen 13: Details — title, MS dropdown + First Name, Last Name, Phone, Email, Gender (Male/Female/Other), Register.
class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  int _genderIndex = 1;

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
              Text('Details', style: AppTextStyles.headingLarge(context).copyWith(fontSize: 28)),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: AppTextField(
                      label: null,
                      hint: 'MS',
                      suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: AppTextField(label: 'First Name', hint: 'Sayali')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Last Name', hint: 'Rane'),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Phone', hint: '9112345678', keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Email', hint: 'sayalirane@gmail.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: AppSpacing.lg),
              Text('Gender', style: AppTextStyles.bodyMedium(context)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _genderChip(context, 'Male', 0),
                  const SizedBox(width: AppSpacing.sm),
                  _genderChip(context, 'Female', 1),
                  const SizedBox(width: AppSpacing.sm),
                  _genderChip(context, 'Other', 2),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppPrimaryButton(
                label: 'Register',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderChip(BuildContext context, String label, int index) {
    final selected = _genderIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _genderIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.headerYellow : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: selected ? AppColors.white : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
