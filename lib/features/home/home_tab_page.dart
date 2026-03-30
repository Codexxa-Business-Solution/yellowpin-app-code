import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/api_config.dart';
import '../../core/api/jobs_api.dart';

/// Home tab: profile header, search, banners, category chips, My Vacancies (from API), Recent People Applied, Event. Uses assets from assets/img1.
class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  final _jobsApi = JobsApi();
  List<Map<String, dynamic>> _myVacancies = [];
  bool _vacanciesLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadMyVacancies();
  }

  Future<void> _loadUserRole() async {
    final role = await AuthStorage.getUserRole();
    if (!mounted) return;
    setState(() => _userRole = role?.trim().toLowerCase());
  }

  bool get _isInstitute => _userRole == 'institute';

  /// Job seeker home matches the high-fidelity dashboard (recommended jobs, categories, etc.).
  bool get _isJobSeeker =>
      _userRole == 'job seeker' || _userRole == 'job_seeker';

  bool get _useJobSeekerDashboard => _isJobSeeker || _isInstitute;

  Future<void> _loadMyVacancies() async {
    setState(() => _vacanciesLoading = true);
    final res = await _jobsApi.getJobs(status: 'active', perPage: 10);
    if (!mounted) return;
    setState(() {
      _vacanciesLoading = false;
      if (res.isOk && res.data is Map) {
        final list = (res.data as Map)['data'];
        _myVacancies = list is List
            ? list.map((e) {
                if (e is! Map) return <String, dynamic>{};
                return Map<String, dynamic>.from(e);
              }).toList()
            : [];
      } else {
        _myVacancies = [];
      }
    });
  }

  static String _formatNum(dynamic n) {
    if (n == null) return '0';
    final x = n is num ? n.toDouble() : double.tryParse(n.toString());
    if (x == null) return n.toString();
    String tidy(double v, {int decimals = 2}) =>
        v.toStringAsFixed(decimals).replaceFirst(RegExp(r'\.?0+$'), '');
    if (x >= 100000) return '${tidy(x / 100000, decimals: 2)}L';
    if (x >= 1000) return '${tidy(x / 1000, decimals: 2)}k';
    return tidy(x, decimals: 2);
  }

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _loadMyVacancies();
          },
          color: AppColors.headerYellow,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isJobSeeker)
                  _buildJobSeekerHeader(context)
                else
                  _buildDefaultHomeHeader(context),
                _buildSearchBar(context),
                if (_useJobSeekerDashboard) ...[
                  _buildDashboardBanners(context),
                  _buildDashboardRecommendedJobs(context),
                  _buildDashboardBrowseCategory(context),
                  _buildDashboardRecentJobs(context),
                  _buildDashboardEventSection(context),
                ] else ...[
                  _buildBanners(context),
                  _buildCategoryChips(context),
                  _buildMyVacancies(context),
                  _buildRecentPeopleApplied(context),
                  _buildEventSection(context),
                ],
                SizedBox(height: MediaQuery.of(context).padding.bottom + 70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// HR / Organization / Institute — quick action (+) + notifications.
  Widget _buildDefaultHomeHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(color: AppColors.headerYellow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.profileMenu),
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
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(fontSize: 14, color: AppColors.textPrimary),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppColors.white, size: 22),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(minimumSize: Size.zero),
                ),
              ),
              const SizedBox(width: 8),
              _notificationBell(context),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _headerSearchRow(context),
        ],
      ),
    );
  }

  /// Job seeker dashboard — decorative header, **Hello, Name** line, bell only (no +).
  Widget _buildJobSeekerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD54F), Color(0xFFFFC107), Color(0xFFFFB74D)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 60,
            child: IgnorePointer(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profileMenu),
                      child: _buildProfileAvatar(context),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FutureBuilder<String?>(
                        future: AuthStorage.getUserName(),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.trim();
                          final display = name != null && name.isNotEmpty
                              ? name
                              : 'User';
                          return Text.rich(
                            TextSpan(
                              style: AppTextStyles.headingMedium(context)
                                  .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                              children: [
                                const TextSpan(text: 'Hello, '),
                                TextSpan(
                                  text: display,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    _notificationBell(context, lightBackground: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _headerSearchRow(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationBell(
    BuildContext context, {
    bool lightBackground = false,
  }) {
    final bg = lightBackground
        ? AppColors.white.withValues(alpha: 0.92)
        : Colors.transparent;
    final border = lightBackground
        ? Border.all(color: AppColors.white.withValues(alpha: 0.5))
        : Border.all(color: AppColors.white.withValues(alpha: 0.75));
    final iconColor = lightBackground ? AppColors.textPrimary : AppColors.white;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: border,
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: iconColor,
              size: 22,
            ),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(minimumSize: Size.zero),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.bannerRed,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerSearchRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search job, company, etc..',
              hintStyle: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 22,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryOrange,
                  width: 1.2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: const Icon(
            Icons.tune,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
      ],
    );
  }

  static String _fullProfileImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith(RegExp(r'^https?://'))) return url;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (url.startsWith('/') ? '' : '/') + url;
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
                errorBuilder: (_, __, ___) => _assetImage(
                  AppAssets.dummyProfile,
                  48,
                  48,
                  shape: BoxShape.circle,
                ),
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
            final imageUrl = user is Map
                ? (user['image'] ?? '').toString().trim()
                : '';
            final url = _fullProfileImageUrl(
              imageUrl.isEmpty ? null : imageUrl,
            );
            return ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: url.isEmpty
                    ? _assetImage(
                        AppAssets.dummyProfile,
                        48,
                        48,
                        shape: BoxShape.circle,
                      )
                    : Image.network(
                        url,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _assetImage(
                          AppAssets.dummyProfile,
                          48,
                          48,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    // Search bar is now inside header; this keeps the column structure but we don't duplicate search
    return const SizedBox.shrink();
  }

  Widget _buildDashboardBanners(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.md,
          AppSpacing.screenHorizontal,
          AppSpacing.md,
        ),
        children: [
          _bannerCard(
            context,
            title: 'How to find a perfect job for...',
            buttonLabel: 'Read more',
            image: AppAssets.bannerWoman,
            bgColor: const Color(0xFFD04A64),
          ),
          _bannerCard(
            context,
            title: 'Build your best profile now',
            buttonLabel: 'Read more',
            image: AppAssets.bannerWoman,
            bgColor: const Color(0xFF4E76B5),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardRecommendedJobs(BuildContext context) {
    final jobs = [
      (
        'ABC Company',
        'Pimpri, Pune',
        'Maintenance Technician',
        'Senior  •  Fulltime  •  Remote',
        '₹35K/Month',
      ),
      (
        'ABC Company',
        'Pimpri, Pune',
        'Maintenance Technician',
        'Senior  •  Fulltime  •  Remote',
        '₹35K/Month',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            'Recommended Jobs',
            onSeeAll: () =>
                Navigator.pushNamed(context, AppRoutes.fullTimeJobs),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) =>
                  _recommendedJobCard(context, jobs[i]),
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemCount: jobs.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendedJobCard(
    BuildContext context,
    (String, String, String, String, String) data,
  ) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.fullTimeJobs),
        child: Container(
          width: 228,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _assetImage(
                    AppAssets.dummyProfile,
                    32,
                    32,
                    shape: BoxShape.circle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.$1,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          data.$2,
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.$3,
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                data.$4,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Material(
                    color: AppColors.headerYellow,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.fullTimeJobs),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Apply Now',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data.$5,
                    style: AppTextStyles.headingMedium(
                      context,
                    ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBrowseCategory(BuildContext context) {
    final items = [
      (
        Icons.school_outlined,
        'Internship',
        () => Navigator.pushNamed(context, AppRoutes.myJobs),
      ),
      (
        Icons.handyman_outlined,
        'Apprenticeship',
        () => Navigator.pushNamed(context, AppRoutes.myJobs),
      ),
      (
        Icons.person_search_outlined,
        'Trainee',
        () => Navigator.pushNamed(context, AppRoutes.myJobs),
      ),
      (
        Icons.access_time_outlined,
        'Fresher',
        () => Navigator.pushNamed(context, AppRoutes.myJobs),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            'Browse by Category',
            onSeeAll: () =>
                Navigator.pushNamed(context, AppRoutes.partTimeJobs),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              return SizedBox(
                width: 76,
                child: InkWell(
                  onTap: item.$3,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.98),
                              const Color(0xFFE8EEF7),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.95),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          item.$1,
                          color: const Color(0xFF5A6FB5),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardRecentJobs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            'Recent Jobs',
            onSeeAll: () =>
                Navigator.pushNamed(context, AppRoutes.fullTimeJobs),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.fullTimeJobs),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusMedium,
                  ),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _assetImage(
                          AppAssets.dummyProfile,
                          40,
                          40,
                          shape: BoxShape.circle,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ABC Company',
                                style: AppTextStyles.bodySmall(context)
                                    .copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Product Designer',
                                style: AppTextStyles.headingMedium(context)
                                    .copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Senior  •  Fulltime  •  Remote',
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.bookmark_border, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '₹35k/Month',
                          style: AppTextStyles.headingMedium(
                            context,
                          ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '12 Minute Ago',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardEventSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            'Event',
            onSeeAll: () => Navigator.pushNamed(context, AppRoutes.eventList),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 205,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _eventCard(
                  context,
                  'Tue, Aug 26, 2025, 2:30 PM',
                  'Online',
                  AppAssets.event1,
                ),
                _eventCard(
                  context,
                  'Tue, Aug 26, 2025, 2:30 PM',
                  'Online',
                  AppAssets.event2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildBanners(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        children: [
          _bannerCard(
            context,
            title: 'How to find a perfect job for...',
            buttonLabel: 'Read more',
            image: AppAssets.bannerWoman,
            bgColor: const Color(0xFFD54256),
          ),
          _bannerCard(
            context,
            title: 'How to find a perfect job for...',
            buttonLabel: 'Read more',
            image: AppAssets.bannerWoman,
            bgColor: const Color(0xFF5C6BC0),
          ),
        ],
      ),
    );
  }

  Widget _bannerCard(
    BuildContext context, {
    required String title,
    required String buttonLabel,
    required String image,
    required Color bgColor,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              height: 100,
              child: _assetImage(image, 80, 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final items = [
      (
        Icons.work_outline,
        'Full Time',
        () => Navigator.pushNamed(context, AppRoutes.fullTimeJobs),
      ),
      (
        Icons.access_time,
        'Part Time',
        () => Navigator.pushNamed(context, AppRoutes.partTimeJobs),
      ),
      (
        Icons.description_outlined,
        'Application Received',
        () => Navigator.pushNamed(context, AppRoutes.applicants),
      ),
      (
        Icons.checklist,
        'Shortlist Candidate',
        () => Navigator.pushNamed(context, AppRoutes.shortlisted),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map((e) => _categoryChip(context, e.$1, e.$2, e.$3))
            .toList(),
      ),
    );
  }

  Widget _categoryChip(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Icon(icon, color: const Color(0xFF5C6BC0), size: 26),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyVacancies(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Vacancies',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontSize: 16),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.postedJobsList),
                child: Text(
                  'See all',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_vacanciesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_myVacancies.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No vacancies yet.',
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ..._myVacancies.map((j) => _vacancyCardFromMap(context, j)),
        ],
      ),
    );
  }

  Widget _vacancyCardFromMap(BuildContext context, Map<String, dynamic> j) {
    final title = (j['job_title'] ?? '').toString();
    final user = j['user'];
    final company = user is Map
        ? (user['name'] ?? 'Company').toString()
        : 'Company';
    final location = (j['location'] ?? '').toString();
    final applicants = (j['applications_count'] ?? 0).toString();
    final meta = location.isEmpty
        ? '$applicants applicants'
        : '$location • $applicants applicants';
    final salaryMin = j['salary_min'];
    final salaryMax = j['salary_max'];
    final salaryPeriod = (j['salary_period'] ?? 'monthly')
        .toString()
        .toLowerCase();
    final suffix = salaryPeriod == 'yearly' ? '/Year' : '/Month';
    String salary = '—';
    if (salaryMin != null || salaryMax != null) {
      if (salaryMin != null && salaryMax != null) {
        salary = '₹${_formatNum(salaryMin)}–${_formatNum(salaryMax)}$suffix';
      } else {
        salary = '₹${_formatNum(salaryMin ?? salaryMax)}$suffix';
      }
    }
    final rawId = j['id'];
    final jobId = rawId is int
        ? rawId
        : (rawId != null ? int.tryParse(rawId.toString()) : null);
    return _vacancyCard(context, title, company, meta, salary, jobId);
  }

  Widget _vacancyCard(
    BuildContext context,
    String title,
    String company,
    String meta,
    String salary, [
    int? jobId,
  ]) {
    final parts = meta.split(' • ');
    final applicantsText = parts.length > 1 ? parts.last : meta;
    final locationPart = parts.isNotEmpty ? '${parts.first} • ' : '';
    final profileUrl = _fullProfileImageUrl(AuthStorage.profileImageUrl);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: jobId != null
              ? () => Navigator.pushNamed(
                  context,
                  AppRoutes.jobDetails,
                  arguments: jobId,
                )
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                profileUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          profileUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _assetImage(
                            AppAssets.dummyProfile,
                            44,
                            44,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : _assetImage(
                        AppAssets.dummyProfile,
                        44,
                        44,
                        shape: BoxShape.circle,
                      ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.headingMedium(
                          context,
                        ).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        company,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(text: locationPart),
                            TextSpan(
                              text: applicantsText,
                              style: const TextStyle(
                                color: AppColors.applicantsGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  salary,
                  style: AppTextStyles.headingMedium(
                    context,
                  ).copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPeopleApplied(BuildContext context) {
    final applicants = [
      ('Piyush Patil', 'Site Engineer', AppAssets.applicantProfile),
      ('Amey Shinde', 'Production Incharge', AppAssets.instituteProfile),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent People Applied',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontSize: 16),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.applicants),
                child: Text(
                  'See all',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...applicants.map((a) => _applicantCard(context, a.$1, a.$2, a.$3)),
        ],
      ),
    );
  }

  Widget _applicantCard(
    BuildContext context,
    String name,
    String role,
    String avatar,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _assetImage(avatar, 48, 48, shape: BoxShape.circle),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.headingMedium(
                        context,
                      ).copyWith(fontSize: 15),
                    ),
                    Text(
                      role,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Material(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.jobSeekerDetails,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 8,
                          ),
                          child: Text(
                            'View Resume',
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: AppColors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.applicantsGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.check,
                        color: AppColors.applicantsGreen,
                        size: 22,
                      ),
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
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.bannerRed,
                        size: 22,
                      ),
                      onPressed: () {},
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(
                Icons.bookmark_border,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSection(BuildContext context) {
    final events = [
      ('Tue, Aug 26, 2025, 2:30 PM', 'Online', AppAssets.event1),
      ('Tue, Aug 26, 2025, 2:30 PM', 'Online', AppAssets.event2),
      ('Tue, Aug 26, 2025, 2:30 PM', 'Online', AppAssets.event3),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Event',
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontSize: 16),
              ),
              Text(
                'See all',
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 212,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, i) {
                final e = events[i];
                return _eventCard(context, e.$1, e.$2, e.$3);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(
    BuildContext context,
    String dateTime,
    String location,
    String image,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 200,
            height: 84,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.circleLightGrey,
                child: const Icon(Icons.event, color: AppColors.textSecondary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateTime,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerYellow,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'View more →',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetImage(
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
        child: Icon(
          Icons.person,
          size: width * 0.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
    if (shape == BoxShape.circle) {
      return ClipOval(
        child: SizedBox(width: width, height: height, child: child),
      );
    }
    return SizedBox(width: width, height: height, child: child);
  }
}
