import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/jobs_api.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/api_config.dart';
import '../../core/api/profile_api.dart';

/// Screen 30–31: My Jobs — Posted Jobs | Applied Jobs tabs. Search, filter, job cards, FAB on Posted.
/// **Job seeker:** gradient header + filters (All / Apprenticeship / Internship / Part Time) + browse cards → Job Details.
class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  int _selectedTab = 0; // 0 = Posted Jobs, 1 = Applied Jobs
  int _postedFilterIndex =
      0; // 0 = All, 1 = Internship, 2 = Apprenticeship, 3 = Trainee
  int _instituteFilterIndex =
      0; // 0 = All, 1 = Apprenticeship, 2 = Internship, 3 = Part Time, 4 = Full Time
  /// Job seeker footer: All, Apprenticeship, Internship, Part Time (matches API `job_type`).
  int _jobSeekerFilterIndex = 0;
  String? _role;
  final _jobsApi = JobsApi();
  final _searchController = TextEditingController();
  bool _loadingPosted = false;
  bool _loadingApplied = false;
  List<Map<String, dynamic>> _postedJobs = [];
  List<Map<String, dynamic>> _applications = [];
  String? _errorPosted;
  String? _errorApplied;

  static const List<String> _filterJobTypes = [
    '',
    'internship',
    'apprenticeship',
    'trainee',
  ];
  static const List<String> _instituteJobTypes = [
    '',
    'apprenticeship',
    'internship',
    'part_time',
    'full_time',
  ];
  static const List<String> _jobSeekerJobTypes = [
    '',
    'apprenticeship',
    'internship',
    'part_time',
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadPostedJobs();
    _loadAppliedJobs();
  }

  Future<void> _loadRole() async {
    final role = await AuthStorage.getUserRole();
    if (!mounted) return;
    setState(() => _role = role?.trim().toLowerCase());
  }

  bool get _isInstitute => _role == 'institute';

  bool get _isJobSeeker => _role == 'job seeker' || _role == 'job_seeker';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPostedJobs() async {
    setState(() {
      _loadingPosted = true;
      _errorPosted = null;
    });
    final String? jobType;
    if (_isInstitute) {
      jobType = _instituteFilterIndex < _instituteJobTypes.length
          ? _instituteJobTypes[_instituteFilterIndex]
          : null;
    } else if (_isJobSeeker) {
      jobType = _jobSeekerFilterIndex < _jobSeekerJobTypes.length
          ? _jobSeekerJobTypes[_jobSeekerFilterIndex]
          : null;
    } else {
      jobType = _postedFilterIndex < _filterJobTypes.length
          ? _filterJobTypes[_postedFilterIndex]
          : null;
    }
    final jt = (jobType == null || jobType.isEmpty) ? null : jobType;
    final res = await _jobsApi.getJobs(
      status: 'active',
      jobType: jt,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      mine: !_isJobSeeker && !_isInstitute,
    );
    if (!mounted) return;
    setState(() {
      _loadingPosted = false;
      if (res.isOk && res.data is Map) {
        final data = res.data as Map;
        final list = data['data'];
        _postedJobs = list is List
            ? list.map((e) {
                if (e is! Map) return <String, dynamic>{};
                return Map<String, dynamic>.from(e);
              }).toList()
            : [];
      } else {
        _errorPosted = res.error ?? 'Failed to load jobs';
      }
    });
  }

  Future<void> _loadAppliedJobs() async {
    setState(() {
      _loadingApplied = true;
      _errorApplied = null;
    });
    final res = await _jobsApi.getApplications();
    if (!mounted) return;
    setState(() {
      _loadingApplied = false;
      if (res.isOk && res.data is Map) {
        final data = res.data as Map;
        final list = data['data'];
        _applications = list is List
            ? list.map((e) {
                if (e is! Map) return <String, dynamic>{};
                return Map<String, dynamic>.from(e);
              }).toList()
            : [];
      } else {
        _errorApplied = res.error ?? 'Failed to load applications';
      }
    });
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
      appBar: _isJobSeeker
          ? null
          : AppBar(
              backgroundColor: AppColors.headerYellow,
              elevation: 0,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              title: Text(
                _isInstitute ? 'All Jobs' : 'My Jobs',
                style: AppTextStyles.screenTitle(
                  context,
                ).copyWith(fontSize: 20),
              ),
              centerTitle: true,
            ),
      body: _isInstitute
          ? _buildInstituteBody(context)
          : _isJobSeeker
          ? _buildJobSeekerBody(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchRow(context),
                _buildTabs(context),
                if (_selectedTab == 0) _buildFilterPills(context),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildPostedJobsList(context)
                      : _buildAppliedJobsList(context),
                ),
              ],
            ),
      floatingActionButton: !_isJobSeeker && (_isInstitute || _selectedTab == 0)
          ? FloatingActionButton(
              heroTag: 'my_jobs_fab',
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.jobForm1);
                if (mounted) _loadPostedJobs();
              },
              backgroundColor: AppColors.headerYellow,
              child: const Icon(Icons.add, color: AppColors.textPrimary),
            )
          : null,
    );
  }

  /// Job seeker: gradient header + search + horizontal filters + browse list → [AppRoutes.jobDetails].
  Widget _buildJobSeekerBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildJobSeekerHeader(context),
        _buildJobSeekerFilterPills(context),
        Expanded(child: _buildJobSeekerJobsList(context)),
      ],
    );
  }

  Widget _buildJobSeekerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB74D), Color(0xFFFFC107), Color(0xFFFFD54F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -20,
              right: -30,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
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
                        child: _jobSeekerAvatar(context),
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello,',
                                  style: AppTextStyles.bodySmall(context)
                                      .copyWith(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                Text(
                                  display,
                                  style: AppTextStyles.headingMedium(context)
                                      .copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      _jobSeekerNotificationBell(context),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
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
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _loadPostedJobs(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _loadPostedJobs,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            width: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobSeekerAvatar(BuildContext context) {
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
                errorBuilder: (_, __, ___) => _jobSeekerAvatarAsset(),
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
                    ? _jobSeekerAvatarAsset()
                    : Image.network(
                        url,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _jobSeekerAvatarAsset(),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _jobSeekerAvatarAsset() {
    return ClipOval(
      child: Image.asset(
        AppAssets.dummyProfile,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 48,
          height: 48,
          color: AppColors.circleLightGrey,
          child: const Icon(Icons.person, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _jobSeekerNotificationBell(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withValues(alpha: 0.92),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
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

  Widget _buildJobSeekerFilterPills(BuildContext context) {
    const labels = ['All', 'Apprenticeship', 'Internship', 'Part Time'];
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = _jobSeekerFilterIndex == i;
            return Padding(
              padding: EdgeInsets.only(
                right: i < labels.length - 1 ? AppSpacing.sm : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _jobSeekerFilterIndex = i);
                  _loadPostedJobs();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryOrange : AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: active
                          ? AppColors.primaryOrange
                          : AppColors.inputBorder,
                    ),
                    boxShadow: active
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Text(
                    labels[i],
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildJobSeekerJobsList(BuildContext context) {
    if (_loadingPosted) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorPosted != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorPosted!,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadPostedJobs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_postedJobs.isEmpty) {
      return Center(
        child: Text(
          'No jobs found.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPostedJobs,
      color: AppColors.primaryOrange,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.sm,
        ),
        children: _postedJobs.map((j) {
          final title = (j['job_title'] ?? 'Job').toString();
          final location = (j['location'] ?? 'Pune').toString();
          final work = _jobSeekerWorkLabel(j);
          final subtitle = location.isEmpty ? work : '$location • $work';
          final jobTypeRaw = (j['job_type'] ?? '').toString();
          final tag = _formatJobType(jobTypeRaw);
          final salary = _jobSeekerSalaryLine(j);
          final timeAgo = _formatRelativeTime(_parseDateTime(j['created_at']));
          final id = j['id'];
          final jobId = id is int ? id : int.tryParse(id.toString());
          return _JobSeekerBrowseCard(
            title: title,
            locationLine: subtitle,
            salary: salary,
            tag: tag.isEmpty ? 'Job' : tag,
            timeAgo: timeAgo,
            onTap: jobId != null
                ? () => Navigator.pushNamed(
                    context,
                    AppRoutes.jobDetails,
                    arguments: jobId,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  String _jobSeekerWorkLabel(Map<String, dynamic> j) {
    final mode = (j['work_mode'] ?? j['work_type'] ?? j['location_type'] ?? '')
        .toString()
        .toLowerCase();
    if (mode.contains('remote')) return 'Remote';
    if (mode.contains('hybrid')) return 'Hybrid';
    if (mode.contains('site') || mode.contains('on')) return 'On Site';
    final interview = (j['interview_mode'] ?? '').toString().toLowerCase();
    if (interview.contains('remote')) return 'Remote';
    return 'On Site';
  }

  String _jobSeekerSalaryLine(Map<String, dynamic> j) {
    final salaryMin = j['salary_min'];
    final salaryMax = j['salary_max'];
    final period = (j['salary_period'] ?? j['salary_unit'] ?? 'monthly')
        .toString()
        .toLowerCase();
    if (salaryMin == null && salaryMax == null) return '—';
    if (period.contains('hour') || period.contains('hr')) {
      final n = salaryMin ?? salaryMax;
      return '₹${_formatNum(n)}/1 Hour';
    }
    final suffix = period == 'yearly' ? '/Year' : '/Month';
    if (salaryMin != null && salaryMax != null) {
      return '₹${_formatNum(salaryMin)}–${_formatNum(salaryMax)}$suffix';
    }
    final n = salaryMin ?? salaryMax;
    return '₹${_formatNum(n)}$suffix';
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Recently';
    final now = DateTime.now();
    var diff = now.difference(dt);
    if (diff.isNegative) diff = Duration.zero;
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} Minute Ago';
    if (diff.inHours < 24)
      return '${diff.inHours} Hour${diff.inHours == 1 ? '' : 's'} Ago';
    if (diff.inDays < 7)
      return '${diff.inDays} Day${diff.inDays == 1 ? '' : 's'} Ago';
    return '${diff.inDays} d Ago';
  }

  Widget _buildInstituteBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchRow(context),
        _buildInstituteFilterPills(context),
        Expanded(
          child: _instituteFilterIndex == 0
              ? _buildInstituteCompaniesList(context)
              : _buildInstituteJobsList(context),
        ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
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
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _loadPostedJobs(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _selectedTab == 0 ? _loadPostedJobs : null,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: const Icon(Icons.tune, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? AppColors.headerYellow.withValues(alpha: 0.25)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(
                    color: _selectedTab == 0
                        ? AppColors.headerYellow
                        : AppColors.inputBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Posted Jobs',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: _selectedTab == 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedTab == 0
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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
                  color: _selectedTab == 1
                      ? AppColors.headerYellow.withValues(alpha: 0.25)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(
                    color: _selectedTab == 1
                        ? AppColors.headerYellow
                        : AppColors.inputBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Applied Jobs',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: _selectedTab == 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedTab == 1
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(BuildContext context) {
    const labels = ['All', 'Internship', 'Apprenticeship', 'Trainee'];
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = _postedFilterIndex == i;
            return Padding(
              padding: EdgeInsets.only(
                right: i < labels.length - 1 ? AppSpacing.sm : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _postedFilterIndex = i);
                  _loadPostedJobs();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.headerYellow : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? AppColors.headerYellow
                          : AppColors.inputBorder,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInstituteFilterPills(BuildContext context) {
    const labels = [
      'All',
      'Apprenticeship',
      'Internship',
      'Part Time',
      'Full Time',
    ];
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = _instituteFilterIndex == i;
            return Padding(
              padding: EdgeInsets.only(
                right: i < labels.length - 1 ? AppSpacing.sm : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _instituteFilterIndex = i);
                  _loadPostedJobs();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.headerYellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? AppColors.headerYellow
                          : AppColors.inputBorder,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPostedJobsList(BuildContext context) {
    if (_loadingPosted) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorPosted != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorPosted!,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadPostedJobs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_postedJobs.isEmpty) {
      return Center(
        child: Text(
          'No posted jobs yet.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPostedJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        children: _postedJobs.map((j) {
          final title = (j['job_title'] ?? '').toString();
          final user = j['user'];
          final company = user is Map
              ? (user['name'] ?? 'Company').toString()
              : 'Company';
          final location = (j['location'] ?? '').toString();
          final applicants =
              (j['applications_count'] ?? j['applications'] is List
                      ? (j['applications'] as List).length
                      : 0)
                  .toString();
          final applicantsText = location.isEmpty
              ? '$applicants applicants'
              : '$location • $applicants applicants';
          final jobType = (j['job_type'] ?? '').toString();
          final tag = jobType.isEmpty ? 'Job' : _formatJobType(jobType);
          final salaryMin = j['salary_min'];
          final salaryMax = j['salary_max'];
          final salaryPeriod = (j['salary_period'] ?? 'monthly')
              .toString()
              .toLowerCase();
          final suffix = salaryPeriod == 'yearly' ? '/Year' : '/Month';
          String salary = '';
          if (salaryMin != null || salaryMax != null) {
            if (salaryMin != null && salaryMax != null) {
              salary =
                  '₹${_formatNum(salaryMin)}–${_formatNum(salaryMax)}$suffix';
            } else if (salaryMin != null) {
              salary = '₹${_formatNum(salaryMin)}$suffix';
            } else {
              salary = '₹${_formatNum(salaryMax)}$suffix';
            }
          } else {
            salary = '—';
          }
          final id = j['id'];
          return _PostedJobCard(
            title: title,
            company: company,
            applicants: applicantsText,
            tag: tag,
            salary: salary,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.jobDetails,
              arguments: id,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInstituteCompaniesList(BuildContext context) {
    if (_loadingPosted) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorPosted != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _errorPosted!,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_postedJobs.isEmpty) {
      return Center(
        child: Text(
          'No jobs found.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final grouped = <String, Map<String, dynamic>>{};
    for (final job in _postedJobs) {
      final name = _extractCompanyDisplayName(job);
      final location = (job['location'] ?? '').toString().trim();
      final normalizedLocation = location.toLowerCase();
      final key = '${name.toLowerCase()}|$normalizedLocation';
      final createdAt = _parseDateTime(job['created_at']);
      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'name': name,
          'location': location,
          'count': 0,
          'latestCreatedAt': createdAt,
        };
      }
      grouped[key]!['count'] = (grouped[key]!['count'] as int) + 1;
      final latest = grouped[key]!['latestCreatedAt'] as DateTime?;
      if (createdAt != null && (latest == null || createdAt.isAfter(latest))) {
        grouped[key]!['latestCreatedAt'] = createdAt;
      }
    }
    final cards = grouped.values.toList();

    return RefreshIndicator(
      onRefresh: _loadPostedJobs,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.sm,
        ),
        itemCount: cards.length,
        itemBuilder: (context, i) {
          final e = cards[i];
          return _InstituteCompanyCard(
            name: (e['name'] ?? '').toString(),
            location: (e['location'] ?? '').toString(),
            count: (e['count'] ?? 0) as int,
            ageLabel: _formatDaysAgo(e['latestCreatedAt'] as DateTime?),
          );
        },
      ),
    );
  }

  String _extractCompanyDisplayName(Map<String, dynamic> job) {
    final user = job['user'];
    final company = job['company'];
    final candidates = <dynamic>[
      job['company_name'],
      job['organization_name'],
      job['organisation_name'],
      job['institute_name'],
      company is Map ? company['name'] : null,
      company is Map ? company['company_name'] : null,
      user is Map ? user['company_name'] : null,
      user is Map ? user['organization_name'] : null,
      user is Map ? user['organisation_name'] : null,
      user is Map ? user['institute_name'] : null,
    ];
    for (final value in candidates) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return 'Company';
  }

  Widget _buildInstituteJobsList(BuildContext context) {
    if (_loadingPosted) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorPosted != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _errorPosted!,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_postedJobs.isEmpty) {
      return Center(
        child: Text(
          'No jobs found.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPostedJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.sm,
        ),
        children: _postedJobs.map((j) {
          final title = (j['job_title'] ?? '').toString();
          final user = j['user'];
          final company = user is Map
              ? (user['name'] ?? 'Company').toString()
              : 'Company';
          final jobType = _formatJobType((j['job_type'] ?? '').toString());
          final location = (j['location'] ?? 'On site').toString();
          final salaryMin = j['salary_min'];
          final salaryMax = j['salary_max'];
          final salaryPeriod = (j['salary_period'] ?? 'monthly')
              .toString()
              .toLowerCase();
          final suffix = salaryPeriod == 'yearly' ? '/Year' : '/Month';
          final filterTag = _instituteFilterIndex > 0
              ? const [
                  'All',
                  'Apprenticeship',
                  'Internship',
                  'Part Time',
                  'Full Time',
                ][_instituteFilterIndex]
              : '';
          String salary = '—';
          if (salaryMin != null || salaryMax != null) {
            if (salaryMin != null && salaryMax != null) {
              salary =
                  '₹${_formatNum(salaryMin)}–${_formatNum(salaryMax)}$suffix';
            } else {
              final n = salaryMin ?? salaryMax;
              salary = '₹${_formatNum(n)}$suffix';
            }
          }
          final id = j['id'];
          return _InstituteJobCard(
            title: title.isEmpty ? 'Job' : title,
            company: company,
            typeLabel: jobType,
            location: location,
            salary: salary,
            tag: filterTag,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.jobDetails,
              arguments: id,
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _formatJobType(String v) {
    if (v.isEmpty) return 'Job';
    final k = v.toLowerCase().replaceAll('_', ' ');
    return k.isEmpty ? v : (k[0].toUpperCase() + k.substring(1));
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

  static String _fullProfileImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith(RegExp(r'^https?://'))) return url;
    final base = ApiConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (url.startsWith('/') ? '' : '/') + url;
  }

  Widget _buildAppliedJobsList(BuildContext context) {
    if (_loadingApplied) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorApplied != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorApplied!,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadAppliedJobs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_applications.isEmpty) {
      return Center(
        child: Text(
          'No applications yet.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAppliedJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        children: _applications.map((a) {
          final jobPost = a['job_post'] ?? a['jobPost'];
          if (jobPost is! Map) {
            return const SizedBox.shrink();
          }
          final title = (jobPost['job_title'] ?? '').toString();
          final user = jobPost['user'];
          final company = user is Map
              ? (user['name'] ?? 'Company').toString()
              : 'Company';
          final location = (jobPost['location'] ?? '').toString();
          final jobType = (jobPost['job_type'] ?? '').toString();
          final tag = _formatJobType(jobType);
          final salaryMin = jobPost['salary_min'];
          final salaryMax = jobPost['salary_max'];
          final salaryPeriod = (jobPost['salary_period'] ?? 'monthly')
              .toString()
              .toLowerCase();
          final suffix = salaryPeriod == 'yearly' ? '/Year' : '/Month';
          String salary = '—';
          if (salaryMin != null || salaryMax != null) {
            if (salaryMin != null && salaryMax != null) {
              salary =
                  '₹${_formatNum(salaryMin)}–${_formatNum(salaryMax)}$suffix';
            } else {
              final n = salaryMin ?? salaryMax;
              salary = '₹${_formatNum(n)}$suffix';
            }
          }
          final jobId = jobPost['id'];
          return _AppliedJobCard(
            title: title,
            company: company,
            locationType: location.isEmpty ? 'On site' : location,
            tag: tag,
            salary: salary,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.jobDetails,
              arguments: jobId,
            ),
          );
        }).toList(),
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDaysAgo(DateTime? dt) {
    if (dt == null) return '0 d';
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    final days = diff < 0 ? 0 : diff;
    return '$days d';
  }
}

/// Job seeker browse card — matches footer **My Jobs** design (title, location • work, salary, type pill, time).
class _JobSeekerBrowseCard extends StatelessWidget {
  const _JobSeekerBrowseCard({
    required this.title,
    required this.locationLine,
    required this.salary,
    required this.tag,
    required this.timeAgo,
    this.onTap,
  });

  final String title;
  final String locationLine;
  final String salary;
  final String tag;
  final String timeAgo;
  final VoidCallback? onTap;

  static Color _tagBg(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('internship')) return const Color(0xFFE8F5E9);
    if (t.contains('part')) return const Color(0xFFE8EAF6);
    if (t.contains('apprentice')) return const Color(0xFFE1F5FE);
    return AppColors.applicantsGreen.withValues(alpha: 0.18);
  }

  static Color _tagFg(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('internship')) return const Color(0xFF2E7D32);
    if (t.contains('part')) return const Color(0xFF283593);
    if (t.contains('apprentice')) return const Color(0xFF0277BD);
    return AppColors.applicantsGreen;
  }

  @override
  Widget build(BuildContext context) {
    final bg = _tagBg(tag);
    final fg = _tagFg(tag);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.inputBorder.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.circleLightGrey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.headingMedium(
                            context,
                          ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationLine,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.bookmark_border,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      salary,
                      style: AppTextStyles.headingMedium(
                        context,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostedJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String applicants;
  final String tag;
  final String salary;
  final VoidCallback? onTap;

  const _PostedJobCard({
    required this.title,
    required this.company,
    required this.applicants,
    required this.tag,
    required this.salary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExperienced = tag == 'Experienced';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(child: _PostedJobAvatar()),
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
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    applicants,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.applicantsGreen, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExperienced
                        ? AppColors.linkBlue.withValues(alpha: 0.15)
                        : AppColors.applicantsGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11,
                      color: isExperienced
                          ? AppColors.linkBlue
                          : AppColors.applicantsGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  salary,
                  style: AppTextStyles.headingMedium(
                    context,
                  ).copyWith(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostedJobAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final url = _MyJobsPageState._fullProfileImageUrl(
      AuthStorage.profileImageUrl,
    );
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Image.asset(
      AppAssets.vacancyLogo1,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 48,
        height: 48,
        color: AppColors.circleLightGrey,
        child: const Icon(Icons.person, color: AppColors.textSecondary),
      ),
    );
  }
}

class _InstituteCompanyCard extends StatelessWidget {
  const _InstituteCompanyCard({
    required this.name,
    required this.location,
    required this.count,
    required this.ageLabel,
  });

  final String name;
  final String location;
  final int count;
  final String ageLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.circleLightGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.headingMedium(
                    context,
                  ).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Location: ${location.isEmpty ? 'N/A' : location}',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$count Job Post',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.applicantsGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ageLabel,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstituteJobCard extends StatelessWidget {
  const _InstituteJobCard({
    required this.title,
    required this.company,
    required this.typeLabel,
    required this.location,
    required this.salary,
    required this.tag,
    this.onTap,
  });

  final String title;
  final String company;
  final String typeLabel;
  final String location;
  final String salary;
  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.circleLightGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.textSecondary),
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
                    ).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Senior  •  ${typeLabel.isEmpty ? 'Fulltime' : typeLabel}  •  ${location.isEmpty ? 'Remote' : location}',
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '10 application',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.applicantsGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        salary,
                        style: AppTextStyles.headingMedium(
                          context,
                        ).copyWith(fontSize: 16),
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
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (tag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF80CCE2)),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: const Color(0xFF1D9CC4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Icon(Icons.bookmark_border, color: AppColors.textPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppliedJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String locationType;
  final String tag;
  final String salary;
  final VoidCallback? onTap;

  const _AppliedJobCard({
    required this.title,
    required this.company,
    required this.locationType,
    required this.tag,
    required this.salary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExperienced = tag == 'Experienced';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.circleLightGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.textSecondary),
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
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textPrimary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationType,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textPrimary, fontSize: 12),
                      children: [
                        const TextSpan(
                          text: 'Applied ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: '1 day Ago',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExperienced
                        ? AppColors.linkBlue.withValues(alpha: 0.15)
                        : AppColors.applicantsGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11,
                      color: isExperienced
                          ? AppColors.linkBlue
                          : AppColors.applicantsGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textPrimary, fontSize: 12),
                    children: [
                      TextSpan(
                        text: salary.split('/').first,
                        style: AppTextStyles.headingMedium(
                          context,
                        ).copyWith(fontSize: 14),
                      ),
                      const TextSpan(text: '/Month'),
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
