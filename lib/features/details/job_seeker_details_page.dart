import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_assets.dart';

/// Screen 27: Job Seeker Details — yellow header, profile banner, contact, About Us, Education, College, Experience, Proceed For Interview.
class JobSeekerDetailsPage extends StatelessWidget {
  const JobSeekerDetailsPage({super.key});

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
        title: Text('Job Seeker Details', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileBanner(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(context, 'About Us', _buildAboutContent(context)),
                  _buildSection(context, 'Education Details', _buildEducationContent(context)),
                  _buildSection(context, 'College Details', _buildCollegeContent(context)),
                  _buildSection(context, 'Experience Details', _buildExperienceContent(context)),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBanner(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1565C0), const Color(0xFF1565C0).withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _WavePainter(),
          ),
        ),
        Positioned(
          left: AppSpacing.screenHorizontal,
          top: 24,
          child: ClipOval(
            child: Image.asset(
              AppAssets.applicantProfile,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.circleLightGrey,
                child: Icon(Icons.person, size: 48, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.screenHorizontal,
          top: 36,
          child: Column(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.check_circle, color: AppColors.applicantsGreen, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close, color: AppColors.bannerRed, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border, color: AppColors.textSecondary, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: AppSpacing.screenHorizontal,
          bottom: -48,
          right: AppSpacing.screenHorizontal,
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 56, 0, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roshan Patil',
                  style: AppTextStyles.headingMedium(context).copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project Manager',
                  style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mumbai, Maharashtra, India',
                  style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('+91 9876543210', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: AppSpacing.xxl),
                    const Icon(Icons.email, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('example@gmail.com', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.inputBorder, height: 1),
          const SizedBox(height: AppSpacing.md),
          content,
        ],
      ),
    );
  }

  Widget _buildAboutContent(BuildContext context) {
    return Text(
      'Dedicated Project Manager with experience in planning, coordinating, and delivering projects on time. Focused on teamwork, quality, and smooth execution.',
      style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, height: 1.5),
    );
  }

  Widget _buildEducationContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(context, 'Qualification', 'Diploma'),
        const SizedBox(height: 6),
        _detailRow(context, 'Stream / Specialization', 'Mechanical'),
      ],
    );
  }

  Widget _buildCollegeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(context, 'Name', 'ABC Institute of Technology'),
        const SizedBox(height: 6),
        _detailRow(context, 'University / Board', 'Pune University / MSBTE'),
      ],
    );
  }

  Widget _buildExperienceContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(context, 'Experience Level', '1-2 Years'),
        const SizedBox(height: 6),
        _detailRow(context, 'Company Name', 'ABC Manufacturing Pvt. Ltd'),
        const SizedBox(height: 6),
        _detailRow(context, 'Job Role', 'Machine Operator'),
        const SizedBox(height: 6),
        _detailRow(context, 'Employment Type', 'Apprentice'),
        const SizedBox(height: 6),
        _detailRow(context, 'Duration', 'Jan 2023 - June 2024'),
        const SizedBox(height: 6),
        _detailRow(context, 'Skills', 'CNC Operation | Machine Handling | Quality Inspection'),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.buttonHeight,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
            ),
            child: const Text('Proceed For Interview'),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    for (var i = 0; i < 3; i++) {
      path.moveTo(0, size.height * (0.3 + i * 0.2));
      path.quadraticBezierTo(size.width * 0.25, size.height * (0.2 + i * 0.2), size.width * 0.5, size.height * (0.3 + i * 0.2));
      path.quadraticBezierTo(size.width * 0.75, size.height * (0.4 + i * 0.2), size.width, size.height * (0.3 + i * 0.2));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
