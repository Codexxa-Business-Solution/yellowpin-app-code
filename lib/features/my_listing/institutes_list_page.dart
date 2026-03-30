import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_bottom_nav_theme.dart';

/// My Listing → Institutes: yellow header, search, filter, institute cards.
class InstitutesListPage extends StatelessWidget {
  const InstitutesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final institutes = [
      ('ABC College of Arts & Commerce', 'Operate machines, maintain quality, and ....', AppAssets.instituteProfile),
      ('ABC Institute of Technology (IIT Bombay)', 'Operate machines, maintain quality, and ....', AppAssets.instituteProfile),
      ('ABC Pune University', 'Operate machines, maintain quality, and ....', AppAssets.instituteProfile),
      ('XYZ World Peace University', 'Operate machines, maintain quality, and ....', AppAssets.instituteProfile),
      ('ABC College of Engineering', 'Operate machines, maintain quality, and ....', AppAssets.instituteProfile),
      ('ABC College', 'Operate machines, maintain quality, and ....', AppAssets.instituteProfile),
    ];
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Institutes', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchRow(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: institutes.map((e) => _instituteCard(context, e.$1, e.$2, e.$3)).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search job, company, etc..',
                hintStyle: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppSpacing.borderRadius), border: Border.all(color: AppColors.inputBorder)),
            child: const Icon(Icons.tune, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _instituteCard(BuildContext context, String name, String description, String logo) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.collegeDetails),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                logo,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.circleLightGrey, child: const Icon(Icons.school, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: AppBottomNavTheme.barHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: AppBottomNavTheme.backgroundColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.work_outline, 'My Jobs', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 0)),
          _navItem(Icons.people_outline, 'Network', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 1)),
          _navItem(Icons.home_outlined, 'Home', true, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 2)),
          _navItem(Icons.school_outlined, 'Course', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 3)),
          _navItem(Icons.event_outlined, 'Event', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 4)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? AppBottomNavTheme.selectedColor : AppBottomNavTheme.unselectedColor, size: AppBottomNavTheme.iconSize),
          const SizedBox(height: 2),
          Text(label, style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
