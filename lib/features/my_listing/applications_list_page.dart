import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_bottom_nav_theme.dart';

/// My Listing → Applications: white app bar, search, Applicants | Shortlisted tabs, applicant cards.
class ApplicationsListPage extends StatefulWidget {
  const ApplicationsListPage({super.key});

  @override
  State<ApplicationsListPage> createState() => _ApplicationsListPageState();
}

class _ApplicationsListPageState extends State<ApplicationsListPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: AppColors.headerYellow, statusBarIconBrightness: Brightness.dark),
    );
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Applications', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchRow(context),
          _buildTabs(context),
          Expanded(child: _selectedTab == 0 ? _buildApplicantsList(context) : _buildShortlistedList(context)),
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
          Container(height: 48, width: 48, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppSpacing.borderRadius), border: Border.all(color: AppColors.inputBorder)), child: const Icon(Icons.tune, color: AppColors.textSecondary)),
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
                  color: _selectedTab == 0 ? AppColors.headerYellow.withValues(alpha: 0.25) : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(color: _selectedTab == 0 ? AppColors.headerYellow : AppColors.inputBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Text('Applicants', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.normal, color: _selectedTab == 0 ? AppColors.textPrimary : AppColors.textSecondary)),
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
                  color: _selectedTab == 1 ? AppColors.headerYellow.withValues(alpha: 0.25) : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(color: _selectedTab == 1 ? AppColors.headerYellow : AppColors.inputBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Text('Shortlisted', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.normal, color: _selectedTab == 1 ? AppColors.textPrimary : AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantsList(BuildContext context) {
    final applicants = [('Piyush Patil', 'Project Engineer', '1d ago'), ('Amey Shinde', 'Site Engineer', '3d ago'), ('Smita Shinde', 'Quality Engineer', '5d ago')];
    return ListView(padding: const EdgeInsets.all(AppSpacing.screenHorizontal), children: applicants.map((e) => _applicantCard(context, e.$1, e.$2, e.$3)).toList());
  }

  Widget _buildShortlistedList(BuildContext context) {
    final shortlisted = [('Piyush Patil', 'Project Engineer', '2d ago'), ('Amey Shinde', 'Site Engineer', '4d ago')];
    return ListView(padding: const EdgeInsets.all(AppSpacing.screenHorizontal), children: shortlisted.map((e) => _applicantCard(context, e.$1, e.$2, e.$3)).toList());
  }

  Widget _applicantCard(BuildContext context, String name, String role, String timeAgo) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppSpacing.borderRadius), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(child: Image.asset(AppAssets.applicantProfile, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.circleLightGrey, child: const Icon(Icons.person, color: AppColors.textSecondary)))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: InkWell(onTap: () => Navigator.pushNamed(context, AppRoutes.jobSeekerDetails), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)), Text(role, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary))]))),
              Text(timeAgo, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.jobSeekerDetails), style: ElevatedButton.styleFrom(backgroundColor: AppColors.black, foregroundColor: AppColors.white, side: const BorderSide(color: AppColors.headerYellow), padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius))), child: const Text('View Resume')),
              const SizedBox(width: 8),
              Container(decoration: BoxDecoration(color: AppColors.applicantsGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: IconButton(icon: const Icon(Icons.check, color: AppColors.applicantsGreen, size: 22), onPressed: () {}, padding: const EdgeInsets.all(8))),
              const SizedBox(width: 4),
              Container(decoration: BoxDecoration(color: AppColors.bannerRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)), child: IconButton(icon: const Icon(Icons.close, color: AppColors.bannerRed, size: 22), onPressed: () {}, padding: const EdgeInsets.all(8))),
            ],
          ),
        ],
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
    return GestureDetector(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: selected ? AppBottomNavTheme.selectedColor : AppBottomNavTheme.unselectedColor, size: AppBottomNavTheme.iconSize), const SizedBox(height: 2), Text(label, style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle, maxLines: 1, overflow: TextOverflow.ellipsis)]));
  }
}
