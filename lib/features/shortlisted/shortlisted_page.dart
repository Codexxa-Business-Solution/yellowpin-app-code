import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';

/// Shortlisted screen (Screens 28–29): opened from Home "Shortlist Candidate" chip.
/// Tabs: Applicants | Shortlisted. Candidate cards with View Resume, View More → / action icons; tap opens Job Seeker Details.
class ShortlistedPage extends StatefulWidget {
  const ShortlistedPage({super.key});

  @override
  State<ShortlistedPage> createState() => _ShortlistedPageState();
}

class _ShortlistedPageState extends State<ShortlistedPage> {
  int _selectedTab = 1; // 0 = Applicants, 1 = Shortlisted (default)

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
        title: Text('Shortlisted', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchRow(context),
          _buildTabs(context),
          Expanded(
            child: _selectedTab == 0 ? _buildApplicantsList(context) : _buildShortlistedList(context),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Column(
                  children: [
                    Text(
                      'Applicants',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedTab == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    if (_selectedTab == 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.headerYellow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Column(
                  children: [
                    Text(
                      'Shortlisted',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedTab == 1 ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    if (_selectedTab == 1) ...[
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.applicantsGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<({String name, String designation, String time})> _candidates = [
    (name: 'Piyush Patil', designation: 'Project Engineer', time: '1d ago'),
    (name: 'Amey Shinde', designation: 'Site Engineer', time: '2d ago'),
    (name: 'Smita Shinde', designation: 'Quality Engineer', time: '5d ago'),
  ];

  Widget _buildApplicantsList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.lg),
      children: _candidates
          .map((e) => _ApplicantCard(name: e.name, designation: e.designation, timeAgo: e.time, showActions: true))
          .toList(),
    );
  }

  Widget _buildShortlistedList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.lg),
      children: _candidates
          .map((e) => _ApplicantCard(name: e.name, designation: e.designation, timeAgo: e.time, showActions: false))
          .toList(),
    );
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
            Text(label, style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final String name;
  final String designation;
  final String timeAgo;
  final bool showActions; // true = Applicants (check/X), false = Shortlisted (View More →)

  const _ApplicantCard({
    required this.name,
    required this.designation,
    required this.timeAgo,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.jobSeekerDetails),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Image.asset(
                    AppAssets.applicantProfile,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.circleLightGrey,
                      child: Icon(Icons.person, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(designation, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(timeAgo, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    side: const BorderSide(color: AppColors.headerYellow),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                  ),
                  child: const Text('View Resume'),
                ),
                const Spacer(),
                if (showActions) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.applicantsGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.check, color: AppColors.applicantsGreen, size: 22),
                      onPressed: () {},
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bannerRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.bannerRed, size: 22),
                      onPressed: () {},
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ] else
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.jobSeekerDetails),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View More', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.linkBlue, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, color: AppColors.linkBlue, size: 16),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
