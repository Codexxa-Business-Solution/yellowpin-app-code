import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';

/// Screen 37–39: Student Profile list. Has back arrow.
class StudentProfileListPage extends StatefulWidget {
  const StudentProfileListPage({super.key});

  @override
  State<StudentProfileListPage> createState() => _StudentProfileListPageState();
}

class _StudentProfileListPageState extends State<StudentProfileListPage> {
  final _searchController = TextEditingController();

  final List<(String, String, String)> _profiles = [
    ('Roshan Patil', 'ITI / Diploma in Mechanic...', AppAssets.applicantProfile),
    ('Ashish patil', 'Diploma / BE Mechanical /...', AppAssets.instituteProfile),
    ('Sayali Rane', 'ITI / Diploma in Mechanic...', AppAssets.applicantProfile),
    ('Gaurav Shinde', 'ITI Fabrication / Welderm...', AppAssets.instituteProfile),
    ('Amey Singh', 'ITI / Diploma in Quality /...', AppAssets.applicantProfile),
    ('Piyush Patil', '12th Pass / Computer Co...', AppAssets.instituteProfile),
    ('Piyush Patil', 'ITI / Diploma in Quality /...', AppAssets.instituteProfile),
    ('Piyush Patil', '12th Pass / Computer Co...', AppAssets.instituteProfile),
    ('Piyush Patil', 'ITI / Diploma in Quality / Mech...', AppAssets.instituteProfile),
  ];

  void _goToHomeTab(int index) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: index);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchController.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _profiles
        : _profiles.where((p) => p.$1.toLowerCase().contains(q) || p.$2.toLowerCase().contains(q)).toList();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Student Profiles', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
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
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              itemCount: filtered.length,
              itemBuilder: (context, i) => _profileCard(context, filtered[i].$1, filtered[i].$2, filtered[i].$3),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: AppBottomNavTheme.barHeight + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: AppBottomNavTheme.backgroundColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.work_outline, 'My Jobs', onTap: () => _goToHomeTab(0)),
            _navItem(Icons.people_outline, 'Network', selected: true, onTap: () => _goToHomeTab(1)),
            _navItem(Icons.home_outlined, 'Home', onTap: () => _goToHomeTab(2)),
            _navItem(Icons.school_outlined, 'Course', onTap: () => _goToHomeTab(3)),
            _navItem(Icons.event_outlined, 'Event', onTap: () => _goToHomeTab(4)),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context, String name, String role, String avatar) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              avatar,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.circleLightGrey, child: const Icon(Icons.person)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.jobSeekerDetails),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(role, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          const Icon(Icons.bookmark, color: AppColors.textPrimary, size: 20),
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
