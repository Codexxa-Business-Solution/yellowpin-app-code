import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/courses_api.dart';
import '../../core/api/profile_api.dart';
import '../../widgets/dynamic_profile_header_row.dart';

/// Screen 44–45: All Courses — header (profile or back), search, filter, course cards from API, FAB to create.
/// When [isStandalone] is true (pushed from My Profile → Courses): app bar + back, search row, own bottom nav.
/// When false (shown as tab in shell): profile header with avatar, no duplicate bottom nav — shell provides nav.
class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key, this.isStandalone = false});

  /// True when pushed as a full screen (e.g. from My Profile → Courses); false when shown as a tab in HomeShell.
  final bool isStandalone;

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  final _coursesApi = CoursesApi();
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;
  bool _isInstitute = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    String? role = await AuthStorage.getUserRole();
    if (role == null || role.isEmpty) {
      final res = await ProfileApi().getProfile();
      if (res.isOk && res.data is Map) {
        final data = (res.data as Map)['data'];
        if (data is Map && data['role'] != null) {
          role = data['role'].toString();
          await AuthStorage.setUserRole(role);
        }
      }
    }
    if (!mounted) return;
    setState(() => _isInstitute = role == 'institute');
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _coursesApi.getCourses(perPage: 20);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data is Map) {
        final data = res.data as Map;
        final list = data['data'];
        _courses = list is List
            ? list
                .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{})
                .toList()
            : [];
        _error = null;
      } else {
        _courses = [];
        _error = res.error ?? 'Failed to load courses';
      }
    });
  }

  Future<void> _openCreateCourse() async {
    final created = await Navigator.pushNamed(context, AppRoutes.createCourse);
    if (mounted && created == true) _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final isStandalone = widget.isStandalone;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: isStandalone ? _buildAppBar(context) : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isStandalone) _buildHeader(context),
            if (isStandalone) _buildSearchRow(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCourses,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  children: [
                    Text('All Courses', style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18)),
                    const SizedBox(height: AppSpacing.md),
                    if (_loading)
                      const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Column(
                            children: [
                              Text(_error!, style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.bannerRed), textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.md),
                              TextButton(onPressed: _loadCourses, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    else if (_courses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text('No courses yet.', style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ..._courses.map((c) => _courseCardFromMap(context, c)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isInstitute
          ? FloatingActionButton(
              heroTag: 'course_list_fab',
              onPressed: _openCreateCourse,
              backgroundColor: AppColors.headerYellow,
              child: const Icon(Icons.add, color: AppColors.textPrimary),
            )
          : null,
      bottomNavigationBar: isStandalone ? _buildBottomNav(context) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.headerYellow,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('All Courses', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
      centerTitle: true,
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
            child: const Icon(Icons.tune, color: AppColors.textSecondary, size: 22),
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
          _navItem(Icons.home_outlined, 'Home', false, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 2)),
          _navItem(Icons.school_outlined, 'Course', true, () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false, arguments: 3)),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.headerYellow,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.md),
      child: Column(
        children: [
          DynamicProfileHeaderRow(
            trailing: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.inputBorder)),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(minimumSize: Size.zero),
                    ),
                  ),
                  Positioned(top: 6, right: 6, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.bannerRed, shape: BoxShape.circle))),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
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
                child: const Icon(Icons.tune, color: AppColors.textSecondary, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final List<Color> _cardColors = [
    const Color(0xFF5C6BC0),
    const Color(0xFF1565C0),
    const Color(0xFF00897B),
  ];

  Widget _courseCardFromMap(BuildContext context, Map<String, dynamic> c) {
    final id = c['id'] is int ? c['id'] as int : (int.tryParse(c['id']?.toString() ?? '') ?? 0);
    final title = (c['course_title'] ?? '').toString();
    final eligibility = (c['eligibility'] ?? '').toString();
    final stream = (c['stream'] ?? '').toString();
    final desc = eligibility.isNotEmpty ? (eligibility.length > 60 ? '${eligibility.substring(0, 60)}...' : eligibility) : (stream.isNotEmpty ? stream : '—');
    final user = c['user'];
    final institute = user is Map ? (user['name'] ?? '').toString() : '';
    final duration = (c['duration'] ?? '').toString();
    final location = (c['location'] ?? '').toString();
    final meta = [if (duration.isNotEmpty) duration, if (location.isNotEmpty) location].join(' • ');
    final colorIndex = id % _cardColors.length;
    final imageBg = _cardColors[colorIndex];
    final asset = colorIndex == 0 ? AppAssets.event1 : (colorIndex == 1 ? AppAssets.event2 : AppAssets.event3);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.courseDetail, arguments: id),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadius)),
              child: Container(
                height: 120,
                color: imageBg,
                child: Image.asset(
                  asset,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.school, size: 48, color: AppColors.white.withValues(alpha: 0.8)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16))),
                      IconButton(icon: const Icon(Icons.more_vert, size: 22), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (institute.isNotEmpty) Text(institute, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textPrimary, fontSize: 12)),
                  if (meta.isNotEmpty) ...[const SizedBox(height: 2), Text(meta, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12))],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
