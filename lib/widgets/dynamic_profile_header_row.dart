import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_assets.dart';
import '../core/api/auth_storage.dart';
import '../core/api/profile_api.dart';
import '../core/api/api_config.dart';

/// A row with dynamic profile avatar, "Hello," and user name from API/storage, plus optional trailing widgets.
/// Use on Network, Event, Course (and optionally Home) so the header is consistent everywhere.
class DynamicProfileHeaderRow extends StatelessWidget {
  const DynamicProfileHeaderRow({
    super.key,
    this.trailing = const [],
  });

  final List<Widget> trailing;

  static String _fullProfileImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith(RegExp(r'^https?://'))) return url;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (url.startsWith('/') ? '' : '/') + url;
  }

  static Widget _assetImage(
    String path,
    double width,
    double height, {
    BoxShape shape = BoxShape.rectangle,
    BoxFit fit = BoxFit.contain,
  }) {
    final child = Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.circleLightGrey,
          shape: shape,
        ),
        child: Icon(Icons.person, size: width * 0.5, color: AppColors.textSecondary),
      ),
    );
    if (shape == BoxShape.circle) {
      return ClipOval(
        child: SizedBox(width: width, height: height, child: child),
      );
    }
    return SizedBox(width: width, height: height, child: child);
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AuthStorage.profileImageUrlNotifier,
      builder: (_, cachedUrl, __) {
        final displayUrl = _fullProfileImageUrl(cachedUrl);
        if (displayUrl.isNotEmpty) {
          return ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.network(
                displayUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _assetImage(AppAssets.dummyProfile, 48, 48, shape: BoxShape.circle),
              ),
            ),
          );
        }
        return FutureBuilder<Map?>(
          future: ProfileApi().getProfile().then((res) {
            if (!res.isOk || res.data is! Map) return null;
            final data = (res.data as Map)['data'];
            if (data is Map && data['image'] != null) {
              final url = data['image'].toString().trim();
              if (url.isNotEmpty) AuthStorage.setProfileImageUrl(url);
            }
            return data as Map?;
          }),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final imageUrl = user is Map ? (user['image'] ?? '').toString().trim() : '';
            final url = _fullProfileImageUrl(imageUrl.isEmpty ? null : imageUrl);
            return ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: url.isEmpty
                    ? _assetImage(AppAssets.dummyProfile, 48, 48, shape: BoxShape.circle)
                    : Image.network(
                        url,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _assetImage(AppAssets.dummyProfile, 48, 48, shape: BoxShape.circle),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profileMenu),
          child: _buildProfileAvatar(context),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hello,',
                style: AppTextStyles.bodySmall(context).copyWith(fontSize: 14, color: AppColors.textPrimary),
              ),
              FutureBuilder<String?>(
                future: AuthStorage.getUserName(),
                builder: (context, snapshot) {
                  final name = snapshot.data?.trim();
                  return Text(
                    name != null && name.isNotEmpty ? name : 'User',
                    style: AppTextStyles.headingMedium(context).copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        ...trailing,
      ],
    );
  }
}
