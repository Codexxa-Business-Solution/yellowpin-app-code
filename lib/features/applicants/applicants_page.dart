import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_bottom_nav_theme.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_assets.dart';

/// Applicants screen (Screens 20–22): Institutes | Job Seekers tabs. Institutes: cards with View Excel, Request Access dialog, Success dialog.
class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  int _selectedTab = 0; // 0 = Institutes, 1 = Job Seekers

  void _showRequestAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _RequestAccessDialog(
        onSubmit: () {
          Navigator.pop(ctx);
          _showSuccessDialog(context);
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _SuccessDialog(onClose: () => Navigator.pop(ctx)),
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
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Applicants', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchRow(context),
          _buildTabs(context),
          Expanded(
            child: _selectedTab == 0 ? _buildInstitutesList(context) : _buildJobSeekersList(context),
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
                child: Text(
                  'Institutes',
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Text(
                  'Job Seekers',
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

  Widget _buildInstitutesList(BuildContext context) {
    final institutes = [
      ('ABC College of Arts & Commerce', 'Prestigious government engineering..', 'Request Sent', AppAssets.instituteProfile),
      ('College of Engineering, Pune (ABC)', 'Prestigious government engineering..', 'Approved', AppAssets.instituteProfile),
      ('ABC College of Arts, Science and Commerce, Pune', 'Prestigious government engineering..', null, AppAssets.instituteProfile),
      ('Modern College of Arts, Science and Commerce, Pune', 'Prestigious government engineering..', null, AppAssets.instituteProfile),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.lg),
      children: institutes.map((e) => _InstituteCard(name: e.$1, description: e.$2, status: e.$3, logo: e.$4, onViewExcel: () => _showRequestAccessDialog(context), onAccept: () => _showRequestAccessDialog(context))).toList(),
    );
  }

  Widget _buildJobSeekersList(BuildContext context) {
    final seekers = [
      ('Piyush Patil', 'Project Engineer'),
      ('Amey Shinde', 'Site Engineer'),
      ('Smita Shinde', 'Quality Engineer'),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.lg),
      children: seekers.map((e) => _JobSeekerCard(name: e.$1, designation: e.$2)).toList(),
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
            decoration: selected ? BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), shape: BoxShape.circle) : null,
            child: Icon(icon, color: selected ? AppBottomNavTheme.selectedColor : AppBottomNavTheme.unselectedColor, size: AppBottomNavTheme.iconSize),
          ),
          const SizedBox(height: 2),
          Text(label, style: selected ? AppBottomNavTheme.labelSelectedStyle : AppBottomNavTheme.labelUnselectedStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _InstituteCard extends StatelessWidget {
  final String name;
  final String description;
  final String? status;
  final String logo;
  final VoidCallback onViewExcel;
  final VoidCallback? onAccept;

  const _InstituteCard({required this.name, required this.description, this.status, required this.logo, required this.onViewExcel, this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.headerYellow.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.asset(
                  logo,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: AppColors.circleLightGrey,
                    child: const Icon(Icons.school, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.collegeDetails),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(description, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Approved' ? AppColors.applicantsGreen : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status!, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.white, fontSize: 11)),
                )
              else
                IconButton(icon: const Icon(Icons.more_vert, size: 22), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onViewExcel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.headerYellow),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                ),
                child: const Text('View Excel'),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.applicantsGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: IconButton(icon: const Icon(Icons.check, color: AppColors.applicantsGreen, size: 22), onPressed: onAccept, padding: const EdgeInsets.all(8)),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(color: AppColors.bannerRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: IconButton(icon: const Icon(Icons.close, color: AppColors.bannerRed, size: 22), onPressed: () {}, padding: const EdgeInsets.all(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobSeekerCard extends StatelessWidget {
  final String name;
  final String designation;

  const _JobSeekerCard({required this.name, required this.designation});

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
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                AppAssets.applicantProfile,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const CircleAvatar(radius: 24, backgroundColor: AppColors.circleLightGrey, child: Icon(Icons.person, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)),
                  Text(designation, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.more_vert, size: 22), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
            Container(
              decoration: const BoxDecoration(color: AppColors.applicantsGreen, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.check, color: AppColors.white, size: 20), onPressed: () {}, padding: const EdgeInsets.all(8)),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: const BoxDecoration(color: AppColors.bannerRed, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.close, color: AppColors.white, size: 20), onPressed: () {}, padding: const EdgeInsets.all(8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestAccessDialog extends StatefulWidget {
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  const _RequestAccessDialog({required this.onSubmit, required this.onClose});

  @override
  State<_RequestAccessDialog> createState() => _RequestAccessDialogState();
}

class _RequestAccessDialogState extends State<_RequestAccessDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 60),
                  SizedBox(
                    height: 100,
                    child: Image.asset(
                      AppAssets.requestAccessExcel,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.description, size: 64, color: AppColors.headerYellow),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Request Access to Excel', style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Send a request to get permission to access this Excel file', textAlign: TextAlign.center, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Note:',
                      hintStyle: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: widget.onSubmit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerYellow, foregroundColor: AppColors.textPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius))),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.circleLightGrey, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onClose;

  const _SuccessDialog({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: AppColors.headerYellow, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: AppColors.white, size: 48),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Request Sent Successfully!', textAlign: TextAlign.center, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18)),
                const SizedBox(height: AppSpacing.sm),
                Text('Your access request has been sent for approval.', textAlign: TextAlign.center, style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.headerYellow, foregroundColor: AppColors.textPrimary, elevation: 0),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.circleLightGrey, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
