import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_assets.dart';

/// Screen 24–26: College Details with three tabs (College Info, Course Info, Student Info).
/// Opened when user taps a college name/card on Applicants – Institutes.
class CollegeDetailsPage extends StatefulWidget {
  const CollegeDetailsPage({super.key});

  @override
  State<CollegeDetailsPage> createState() => _CollegeDetailsPageState();
}

class _CollegeDetailsPageState extends State<CollegeDetailsPage> {
  int _selectedTab = 0; // 0 = College Info, 1 = Course Info, 2 = Student Info

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('College Details', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBannerAndProfile(context),
          _buildTabs(context),
          Expanded(
            child: _selectedTab == 0
                ? _buildCollegeInfoContent(context)
                : _selectedTab == 1
                    ? _buildCourseInfoContent(context)
                    : _buildStudentInfoContent(context),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildBannerAndProfile(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner image
        SizedBox(
          width: double.infinity,
          height: 160,
          child: Image.asset(
            AppAssets.bannerWoman,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1565C0),
              child: const Icon(Icons.account_balance, size: 64, color: AppColors.white),
            ),
          ),
        ),
        // Profile section overlapping banner
        Positioned(
          left: AppSpacing.screenHorizontal,
          bottom: -40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipOval(
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.white,
                  child: Image.asset(
                    AppAssets.instituteProfile,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 40, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ABC College of Arts & Commerce', style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Kothrud, Pune, Maharashtra.', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionIcon(Icons.check, AppColors.applicantsGreen),
                        const SizedBox(width: 6),
                        _actionIcon(Icons.close, AppColors.bannerRed),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _actionIcon(Icons.bookmark_border, AppColors.textPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color) {
    final isCircle = color == AppColors.textPrimary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: color == AppColors.textPrimary ? AppColors.textPrimary : color),
        borderRadius: isCircle ? null : BorderRadius.circular(AppSpacing.radiusSmall),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _buildTabs(BuildContext context) {
    const labels = ['College Info', 'Course Info', 'Student Info'];
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inputBorder, width: 1)),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = _selectedTab == i;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[i],
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        color: active ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (active)
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.headerYellow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCollegeInfoContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'General Information'),
          const SizedBox(height: 6),
          Text(
            'Symbosis College of Commerce & Science (ICCS), affiliated and recognised, located in Pune.',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Address'),
          const SizedBox(height: 6),
          Text('Plot No 49, MIDC, Ram Nagar, D2 Block, opposite Ador Power Station, Pune - 411019.', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Email'),
          const SizedBox(height: 6),
          Text('info@mitcoe.edu', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Website'),
          const SizedBox(height: 6),
          Text('www.mitcoe.edu', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Phone'),
          const SizedBox(height: 6),
          Text('+91 9876543210', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'TPO Name'),
          const SizedBox(height: 6),
          Text('Roshan Patil', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildCourseInfoContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Fields'),
          const SizedBox(height: 8),
          _bulletItem('Engineering'),
          _bulletItem('Pharmacy'),
          _bulletItem('Architecture'),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'UG Courses'),
          const SizedBox(height: 8),
          _bulletItem('B.E. Computer Engineering (30 students)'),
          _bulletItem('B.E. Mechanical Engineering (30 students)'),
          _bulletItem('B.Sc. Computer Science (30 students)'),
          _bulletItem('B.Pharm (30 students)'),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'PG Courses'),
          const SizedBox(height: 8),
          _bulletItem('M.E. (All branches)'),
          _bulletItem('MBA'),
          _bulletItem('MCA'),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildStudentInfoContent(BuildContext context) {
    final courses = ['B.E. Mechanical Engineering', 'B.E. Computer Engineering', 'B.Sc. Computer Science'];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        const SizedBox(height: AppSpacing.md),
        ...courses.map((name) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(name, style: AppTextStyles.bodyLarge(context))),
                  const Icon(Icons.lock, color: AppColors.linkBlue, size: 22),
                ],
              ),
            )),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15));
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.bodyMedium(context)),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium(context))),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    final isStudentInfo = _selectedTab == 2;
    final label = isStudentInfo ? 'Access Request' : 'Proceed For Campus';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
            ),
            child: Text(label, style: AppTextStyles.buttonText(context)),
          ),
        ),
      ),
    );
  }
}
