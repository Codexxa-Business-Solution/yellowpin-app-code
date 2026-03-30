import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/profile_api.dart';

/// Screen 1: Splash — orange status bar, white background, faint circular decorations.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _profileApi = ProfileApi();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _bootstrapSessionAndRoute();
  }

  Future<void> _bootstrapSessionAndRoute() async {
    await Future.delayed(const Duration(seconds: 2));
    final token = await AuthStorage.getToken();
    if (!mounted) return;

    // No active session: show welcome/onboarding flow first.
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding1);
      return;
    }

    // Active session: fetch role from backend to keep local role in sync.
    final profileRes = await _profileApi.getProfile();
    if (!mounted) return;

    if (profileRes.isOk && profileRes.data is Map) {
      final data = (profileRes.data as Map)['data'];
      if (data is Map) {
        final role = data['role']?.toString().trim();
        if (role != null && role.isNotEmpty) {
          await AuthStorage.setUserRole(role);
          await AuthStorage.setLastLoginRole(role);
        }
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    // Invalid/expired token: clear session and force login.
    if (profileRes.statusCode == 401) {
      await AuthApi.clearAuth();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding1);
      return;
    }

    // Network/server issue: fall back to cached role and continue to last home.
    final lastRole = await AuthStorage.getLastLoginRole();
    if (lastRole != null && lastRole.trim().isNotEmpty) {
      await AuthStorage.setUserRole(lastRole);
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(AppAssets.authBackground, fit: BoxFit.cover)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 72),
              child: Image.asset(AppAssets.yellowPinLogo, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
