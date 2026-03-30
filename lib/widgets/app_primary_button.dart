import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_button_styles.dart';

/// Full-width black primary button. Same style across screens.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: AppButtonStyles.primary(context),
        child: Text(label),
      ),
    );
  }
}
