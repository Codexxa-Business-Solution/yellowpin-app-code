import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/api_config.dart';
import '../../core/api/jobs_api.dart';

/// My Listing → Posted Jobs: yellow header, search, filter, Active | Completed tabs, job cards from API, FAB.
class PostedJobsListPage extends StatefulWidget {
  const PostedJobsListPage({super.key});

  @override
  State<PostedJobsListPage> createState() => _PostedJobsListPageState();
}

class _PostedJobsListPageState extends State<PostedJobsListPage> {
  int _selectedTab = 0; // 0 = Active, 1 = Completed
  final _jobsApi = JobsApi();
  final _searchController = TextEditingController();
  bool _loadingActive = false;
  bool _loadingCompleted = false;
  List<Map<String, dynamic>> _activeJobs = [];
  List<Map<String, dynamic>> _completedJobs = [];
  String? _errorActive;
  String? _errorCompleted;

  @override
  void initState() {
    super.initState();
    _loadActiveJobs();
    _loadCompletedJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveJobs() async {
    setState(() {
      _loadingActive = true;
      _errorActive = null;
    });
    final search = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();
    final res = await _jobsApi.getJobs(status: 'active', search: search);
    if (!mounted) return;
    setState(() {
      _loadingActive = false;
      if (res.isOk && res.data is Map) {
        final list = (res.data as Map)['data'];
        _activeJobs = list is List
            ? list
                  .map(
                    (e) => e is Map
                        ? Map<String, dynamic>.from(e as Map)
                        : <String, dynamic>{},
                  )
                  .toList()
            : [];
      } else {
        _errorActive = res.error ?? 'Failed to load jobs';
      }
    });
  }

  Future<void> _loadCompletedJobs() async {
    setState(() {
      _loadingCompleted = true;
      _errorCompleted = null;
    });
    final search = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();
    final res = await _jobsApi.getJobs(status: 'closed', search: search);
    if (!mounted) return;
    setState(() {
      _loadingCompleted = false;
      if (res.isOk && res.data is Map) {
        final list = (res.data as Map)['data'];
        _completedJobs = list is List
            ? list
                  .map(
                    (e) => e is Map
                        ? Map<String, dynamic>.from(e as Map)
                        : <String, dynamic>{},
                  )
                  .toList()
            : [];
      } else {
        _errorCompleted = res.error ?? 'Failed to load jobs';
      }
    });
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
        title: Text(
          'Posted Jobs',
          style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchRow(context),
          _buildTabs(context),
          Expanded(
            child: _selectedTab == 0
                ? _buildActiveJobsList(context)
                : _buildCompletedJobsList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'posted_jobs_fab',
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.jobForm1);
          if (mounted) {
            _loadActiveJobs();
            _loadCompletedJobs();
          }
        },
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
              onSubmitted: (_) {
                _loadActiveJobs();
                _loadCompletedJobs();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              _loadActiveJobs();
              _loadCompletedJobs();
            },
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
                  'Active',
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
                  'Completed',
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

  Widget _buildActiveJobsList(BuildContext context) {
    if (_loadingActive) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorActive != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorActive!,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadActiveJobs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_activeJobs.isEmpty) {
      return Center(
        child: Text(
          'No active posted jobs.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadActiveJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: _activeJobs.map((j) => _jobCardFromMap(context, j)).toList(),
      ),
    );
  }

  Widget _buildCompletedJobsList(BuildContext context) {
    if (_loadingCompleted) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorCompleted != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorCompleted!,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadCompletedJobs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_completedJobs.isEmpty) {
      return Center(
        child: Text(
          'No completed jobs.',
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCompletedJobs,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: _completedJobs
            .map((j) => _jobCardFromMap(context, j))
            .toList(),
      ),
    );
  }

  Widget _jobCardFromMap(BuildContext context, Map<String, dynamic> j) {
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
    final jobType = (j['job_type'] ?? '').toString();
    final tag = _formatJobType(jobType);
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
    final id = rawId is int
        ? rawId
        : (rawId != null ? int.tryParse(rawId.toString()) : null);
    return _jobCard(context, title, company, meta, tag, salary, id);
  }

  Widget _jobCard(
    BuildContext context,
    String title,
    String company,
    String meta,
    String tag,
    String salary, [
    int? jobId,
  ]) {
    final isExperienced = tag.toLowerCase().contains('experienced');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (jobId != null) {
            Navigator.pushNamed(
              context,
              AppRoutes.jobDetails,
              arguments: jobId,
            );
          }
        },
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(child: _PostedJobsAvatar()),
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
                    meta,
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

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: AppColors.black),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            Icons.work_outline,
            'My Jobs',
            true,
            () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
              arguments: 0,
            ),
          ),
          _navItem(
            Icons.people_outline,
            'Network',
            false,
            () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
              arguments: 1,
            ),
          ),
          _navItem(
            Icons.home_outlined,
            'Home',
            false,
            () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
              arguments: 2,
            ),
          ),
          _navItem(
            Icons.school_outlined,
            'Course',
            false,
            () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
              arguments: 3,
            ),
          ),
          _navItem(
            Icons.event_outlined,
            'Event',
            false,
            () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (r) => false,
              arguments: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected
                ? AppBottomNavTheme.selectedColor
                : AppBottomNavTheme.unselectedColor,
            size: AppBottomNavTheme.iconSize,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: selected
                ? AppBottomNavTheme.labelSelectedStyle
                : AppBottomNavTheme.labelUnselectedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static String _fullProfileImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith(RegExp(r'^https?://'))) return url;
    final base = ApiConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (url.startsWith('/') ? '' : '/') + url;
  }
}

class _PostedJobsAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final url = _PostedJobsListPageState._fullProfileImageUrl(
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
