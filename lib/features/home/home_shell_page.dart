import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/api/auth_storage.dart';
import 'home_tab_page.dart';
import '../my_jobs/my_jobs_page.dart';
import '../network/network_page.dart';
import '../course/course_list_page.dart';
import '../event/event_list_page.dart';

/// Shell with bottom nav: My Jobs (0), Network (1), Home (2), Course (3), Event (4). Route args: initial tab index.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  /// Which tab body is shown (IndexedStack).
  /// Defaults avoid [LateInitializationError] after hot reload (initState does not re-run).
  int _contentIndex = 2;

  /// Which footer tab is highlighted (may differ for job seeker when Network overlay is open).
  int _navIndex = 2;

  String? _userRole;
  bool _networkOverlay = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initialIndex;
    _contentIndex = (i != null && i >= 0 && i <= 4) ? i : 2;
    _navIndex = _contentIndex;
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final r = await AuthStorage.getUserRole();
    if (!mounted) return;
    setState(() => _userRole = r?.trim().toLowerCase());
  }

  bool get _isJobSeeker =>
      _userRole == 'job seeker' || _userRole == 'job_seeker';

  static const List<_NavItem> _tabs = [
    _NavItem(Icons.work_outline, 'My Jobs'),
    _NavItem(Icons.people_outline, 'Network'),
    _NavItem(Icons.home_outlined, 'Home'),
    _NavItem(Icons.school_outlined, 'Course'),
    _NavItem(Icons.event_outlined, 'Event'),
  ];

  void _dismissNetworkOverlay() {
    setState(() {
      _networkOverlay = false;
      _navIndex = _contentIndex;
    });
  }

  void _onTabTap(int i) {
    if (_isJobSeeker && i == 1) {
      if (_networkOverlay) {
        _dismissNetworkOverlay();
        return;
      }
      setState(() {
        _navIndex = 1;
        _networkOverlay = true;
      });
      return;
    }

    setState(() {
      _networkOverlay = false;
      _navIndex = i;
      _contentIndex = i;
    });

    if (i == 1 && !_isJobSeeker) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNetworkPopup());
    }
  }

  void _showNetworkPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NetworkProfileSheet(
        onStudentProfile: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.studentProfileList);
        },
        onInstituteProfile: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.instituteProfileList);
        },
      ),
    );
  }

  void _jobSeekerOpenOrganizationProfiles() {
    setState(() => _networkOverlay = false);
    Navigator.pushNamed(context, AppRoutes.instituteProfileList);
  }

  void _jobSeekerOpenInstituteProfiles() {
    setState(() => _networkOverlay = false);
    Navigator.pushNamed(context, AppRoutes.institutesList);
  }

  /// Width of the Network popup column — used to center on tab 1 (Network).
  static const double _networkMenuWidth = 92;

  /// Horizontal center of tab index [tabIndex] for 5 equal visual slots (matches [MainAxisAlignment.spaceEvenly] + padding approximation).
  double _networkTabCenterX(double screenWidth, int tabIndex) {
    // Each tab ~ 1/5 of width; center of tab i at (i + 0.5) / 5.
    return screenWidth * (tabIndex + 0.5) / 5;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarHeight = AppBottomNavTheme.barHeight + bottomInset;
    final screenW = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          IndexedStack(
            index: _contentIndex,
            children: const [
              MyJobsPage(),
              NetworkPage(),
              HomeTabPage(),
              CourseListPage(),
              EventListPage(),
            ],
          ),
          if (_isJobSeeker && _networkOverlay) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismissNetworkOverlay,
                child: Container(color: Colors.black54),
              ),
            ),
            // Body sits *above* bottomNavigationBar — only a small gap above the nav, not +navBarHeight again.
            Positioned(
              left: _networkTabCenterX(screenW, 1) - _networkMenuWidth / 2,
              bottom: 10,
              width: _networkMenuWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _JobSeekerNetworkFab(
                    icon: Icons.factory_outlined,
                    line1: 'Organization',
                    line2: 'Profile',
                    onTap: _jobSeekerOpenOrganizationProfiles,
                  ),
                  const SizedBox(height: 10),
                  _JobSeekerNetworkFab(
                    icon: Icons.account_balance,
                    line1: 'Institute',
                    line2: 'Profile',
                    onTap: _jobSeekerOpenInstituteProfiles,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        height: navBarHeight,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(color: AppBottomNavTheme.backgroundColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_tabs.length, (i) {
            final item = _tabs[i];
            final selected = _navIndex == i;
            return InkWell(
              onTap: () => _onTabTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: selected
                          ? BoxDecoration(
                              color: AppBottomNavTheme.selectedIconBackground,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Icon(
                        item.icon,
                        color: selected ? AppBottomNavTheme.selectedColor : AppBottomNavTheme.unselectedColor,
                        size: AppBottomNavTheme.iconSize,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

/// Job seeker Network overlay: compact vertical actions anchored **above** the Network tab.
class _JobSeekerNetworkFab extends StatelessWidget {
  final IconData icon;
  final String line1;
  final String line2;
  final VoidCallback onTap;

  const _JobSeekerNetworkFab({
    required this.icon,
    required this.line1,
    required this.line2,
    required this.onTap,
  });

  static const double _diameter = 52;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: _diameter,
              height: _diameter,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inputBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 26, color: AppColors.linkBlue),
            ),
            const SizedBox(height: 6),
            Text(
              line1,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
                height: 1.15,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              line2,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
                height: 1.15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non–job seeker: bottom sheet with Student/Institute profiles.
class _NetworkProfileSheet extends StatelessWidget {
  final VoidCallback onStudentProfile;
  final VoidCallback onInstituteProfile;

  const _NetworkProfileSheet({
    required this.onStudentProfile,
    required this.onInstituteProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(32, 28, 32, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _profileOption(
                  context,
                  icon: Icons.school_rounded,
                  label: 'Student Profiles',
                  onTap: onStudentProfile,
                ),
                const SizedBox(width: 40),
                _profileOption(
                  context,
                  icon: Icons.account_balance_rounded,
                  label: 'Institute Profiles',
                  onTap: onInstituteProfile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: AppColors.linkBlue),
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
