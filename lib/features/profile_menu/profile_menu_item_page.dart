import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Screen 63–71: Profile menu item placeholder. Has back arrow.
class ProfileMenuItemPage extends StatelessWidget {
  const ProfileMenuItemPage({super.key, this.title = 'Menu Item'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Center(child: Text(title, style: AppTextStyles.bodyMedium(context))),
    );
  }
}
