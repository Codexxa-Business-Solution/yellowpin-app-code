import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/jobs_api.dart';
import '../../widgets/dynamic_profile_header_row.dart';

/// Screen 35–36: Network tab — dashboard with header (+ opens Student/Institute popup), search, banners, stats, My Vacancies (from API).
class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final _jobsApi = JobsApi();
  List<Map<String, dynamic>> _myVacancies = [];
  bool _vacanciesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyVacancies();
  }

  Future<void> _loadMyVacancies() async {
    setState(() => _vacanciesLoading = true);
    final res = await _jobsApi.getJobs(status: 'active', perPage: 10);
    if (!mounted) return;
    setState(() {
      _vacanciesLoading = false;
      if (res.isOk && res.data is Map) {
        final list = (res.data as Map)['data'];
        _myVacancies = list is List
            ? list
                  .map(
                    (e) => e is Map
                        ? Map<String, dynamic>.from(e as Map)
                        : <String, dynamic>{},
                  )
                  .toList()
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

  void _showNetworkPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Profile Type',
              style: AppTextStyles.headingMedium(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.linkBlue,
              ),
              title: const Text('Student Profiles'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.studentProfileList);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: AppColors.linkBlue,
              ),
              title: const Text('Institute Profiles'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.instituteProfileList);
              },
            ),
          ],
        ),
      ),
    );
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              _buildBanners(context),
              _buildStatsRow(context),
              _buildMyVacancies(context),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.headerYellow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: DynamicProfileHeaderRow(
        trailing: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: AppColors.textPrimary,
                size: 22,
              ),
              onPressed: _showNetworkPopup,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(minimumSize: Size.zero),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(minimumSize: Size.zero),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Row(
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
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  borderSide: BorderSide.none,
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
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Icon(Icons.tune, color: AppColors.textSecondary),
          ),
        ],
      ),
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
            title: 'Business Consult',
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
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, color: AppColors.white, size: 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final items = [
      (Icons.work_outline, 'Full time', '10'),
      (Icons.access_time, 'Part time', '10'),
      (Icons.description_outlined, 'Applicants', '50'),
      (Icons.checklist, 'Shortlisted', ''),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map((e) => _statChip(context, e.$1, e.$2, e.$3))
            .toList(),
      ),
    );
  }

  Widget _statChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
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
                ClipOval(
                  child: Image.asset(
                    AppAssets.vacancyLogo1,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.circleLightGrey,
                      child: const Icon(
                        Icons.business,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
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
}
