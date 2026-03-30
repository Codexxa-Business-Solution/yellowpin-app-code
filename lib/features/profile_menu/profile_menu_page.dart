import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/auth_storage.dart';

/// Screen 62: Profile Menu — list of options. Has back arrow (internal screen).
class ProfileMenuPage extends StatelessWidget {
  const ProfileMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final items = [
      (Icons.person_outline, 'Edit Profile', AppRoutes.details),
      (Icons.settings_outlined, 'Settings', AppRoutes.profileMenuItem),
      (Icons.notifications_outlined, 'Notifications', AppRoutes.profileMenuItem),
      (Icons.help_outline, 'Help & Support', AppRoutes.profileMenuItem),
      (Icons.privacy_tip_outlined, 'Privacy Policy', AppRoutes.profileMenuItem),
      (Icons.logout, 'Log Out', AppRoutes.home),
    ];
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile Menu', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: ClipOval(
              child: Image.asset(
                AppAssets.dummyProfile,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: FutureBuilder<String?>(
              future: AuthStorage.getUserName(),
              builder: (context, snapshot) {
                final name = snapshot.data?.trim();
                return Text(
                  name != null && name.isNotEmpty ? name : 'User',
                  style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ...items.map((e) => ListTile(
                leading: Icon(e.$1, color: AppColors.textPrimary),
                title: Text(e.$2, style: AppTextStyles.bodyMedium(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (e.$2 == 'Log Out') {
                    final api = AuthApi();
                    await api.signOut();
                    await AuthApi.clearAuth();
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(AppRoutes.signUpAs, (_) => false);
                  } else if (e.$3 == AppRoutes.home) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
                  } else if (e.$3 == AppRoutes.profileMenuItem) {
                    Navigator.pushNamed(context, AppRoutes.profileMenuItem, arguments: e.$2);
                  } else {
                    Navigator.pushNamed(context, e.$3);
                  }
                },
              )),
        ],
      ),
    );
  }
}
