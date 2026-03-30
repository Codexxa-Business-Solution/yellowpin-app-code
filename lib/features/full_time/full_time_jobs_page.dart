import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';

/// Full Time screen (Screens 16–17): Posted Jobs | Find Jobs tabs, job cards, search, filter, FAB. Has back arrow.
class FullTimeJobsPage extends StatefulWidget {
  const FullTimeJobsPage({super.key});

  @override
  State<FullTimeJobsPage> createState() => _FullTimeJobsPageState();
}

class _FullTimeJobsPageState extends State<FullTimeJobsPage> {
  int _selectedTab = 0; // 0 = Posted Jobs, 1 = Find Jobs

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
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Full Time', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchRow(context),
          _buildTabs(context),
          Expanded(
            child: _selectedTab == 0 ? _buildPostedJobsList(context) : _buildFindJobsList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'full_time_fab',
        onPressed: () {},
        backgroundColor: AppColors.headerYellow,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Icon(Icons.tune, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.headerYellow : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(color: _selectedTab == 0 ? AppColors.headerYellow : AppColors.inputBorder),
                ),
                child: Text(
                  'Posted Jobs',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedTab == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.headerYellow : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(color: _selectedTab == 1 ? AppColors.headerYellow : AppColors.inputBorder),
                ),
                child: Text(
                  'Find Jobs',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedTab == 1 ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostedJobsList(BuildContext context) {
    final jobs = [
      ('Site Engineer Trainee', 'ABC Company • On Site', '(Trade Apprenticeship: NATS)', 'Pune • 35 applicants', '₹35k/Month', AppAssets.vacancyLogo1),
      ('Process Engineer', 'ABC Company', null, 'Pune • 10 applicants', '₹45k/Month', AppAssets.vacancyLogo2),
      ('Process Engineer Trainee', 'ABC Company • On Site', '(Trade Apprenticeship: NATS)', 'Pune • 35 applicants', '₹45k/Month', AppAssets.vacancyLogo3),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final j = jobs[i];
        return _postedJobCard(context, j.$1, j.$2, j.$3, j.$4, j.$5, j.$6);
      },
    );
  }

  Widget _postedJobCard(
    BuildContext context,
    String title,
    String company,
    String? tag,
    String meta,
    String salary,
    String logo,
  ) {
    final parts = meta.split(' • ');
    final applicantsText = parts.length > 1 ? parts.last : meta;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _assetImage(logo, 48, 48, shape: BoxShape.circle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(company, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12)),
                if (tag != null) ...[
                  const SizedBox(height: 2),
                  Text(tag, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.linkBlue, fontSize: 11)),
                ],
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12),
                    children: [
                      TextSpan(text: parts.isNotEmpty ? '${parts.first} • ' : ''),
                      TextSpan(text: applicantsText, style: const TextStyle(color: AppColors.applicantsGreen)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(salary, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFindJobsList(BuildContext context) {
    final jobs = [
      ('HR Executive', 'XYZ Company', 'Pune • On Site', 'Experienced', '₹35k/Month', AppAssets.vacancyLogo1),
      ('HR Trainee', 'ABC Company', 'Pune • On Site', 'Internship', '₹25k/Month', AppAssets.vacancyLogo2),
      ('Junior HR Officer', 'XYZ Company', 'Pune • On Site', 'Experienced', '₹30k/Month', AppAssets.vacancyLogo3),
      ('HR Assistant', 'ABC Company', 'Pune • On Site', 'Internship', '₹28k/Month', AppAssets.vacancyLogo1),
      ('Senior HR Executive', 'XYZ Company', 'Pune • On Site', 'Experienced', '₹45k/Month', AppAssets.vacancyLogo2),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final j = jobs[i];
        return _findJobCard(context, j.$1, j.$2, j.$3, j.$4, j.$5, j.$6);
      },
    );
  }

  Widget _findJobCard(
    BuildContext context,
    String title,
    String company,
    String location,
    String type,
    String salary,
    String logo,
  ) {
    final isExperienced = type == 'Experienced';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _assetImage(logo, 48, 48, shape: BoxShape.circle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(company, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(location, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExperienced ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: 11,
                    color: isExperienced ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(salary, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assetImage(String path, double w, double h, {BoxShape shape = BoxShape.rectangle}) {
    final child = Image.asset(
      path,
      width: w,
      height: h,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: AppColors.circleLightGrey, shape: shape),
        child: Icon(Icons.business, size: w * 0.5, color: AppColors.textSecondary),
      ),
    );
    if (shape == BoxShape.circle) {
      return ClipOval(child: SizedBox(width: w, height: h, child: child));
    }
    return SizedBox(width: w, height: h, child: child);
  }

  void _goToHomeTab(int tabIndex) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: tabIndex);
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: AppBottomNavTheme.barHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: AppBottomNavTheme.backgroundColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.work_outline, 'My Jobs', onTap: () => _goToHomeTab(0)),
          _navItem(Icons.people_outline, 'Network', onTap: () => _goToHomeTab(1)),
          _navItem(Icons.home_outlined, 'Home', selected: true, onTap: () => _goToHomeTab(2)),
          _navItem(Icons.school_outlined, 'Course', onTap: () => _goToHomeTab(3)),
          _navItem(Icons.event_outlined, 'Event', onTap: () => _goToHomeTab(4)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool selected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: selected ? BoxDecoration(color: AppBottomNavTheme.selectedIconBackground, shape: BoxShape.circle) : null,
            child: Icon(icon, color: selected ? AppBottomNavTheme.selectedColor : AppBottomNavTheme.unselectedColor, size: AppBottomNavTheme.iconSize),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
