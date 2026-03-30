import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_assets.dart';
import '../../core/api/courses_api.dart';

/// Screen 46–47: Course Details — loads by [courseId], banner, key info, hosted by, Show interest → API then Thank You.
class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, this.courseId});

  final int? courseId;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final _coursesApi = CoursesApi();
  Map<String, dynamic>? _course;
  bool _loading = true;
  String? _error;
  bool _interestSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _loadCourse();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCourse() async {
    final id = widget.courseId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _coursesApi.getCourse(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.isOk && res.data is Map) {
        _course = Map<String, dynamic>.from(res.data as Map);
        _error = null;
      } else {
        _course = null;
        _error = res.error ?? 'Failed to load course';
      }
    });
  }

  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
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
              Text(
                'Thank You for Interest!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium(context).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your interest has been saved.\nOur team will reach out shortly.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onShowInterest() async {
    final id = widget.courseId;
    if (id == null) {
      _showThankYouDialog(context);
      return;
    }
    final res = await _coursesApi.markInterested(id);
    if (!mounted) return;
    if (res.isOk) {
      setState(() => _interestSent = true);
      _showThankYouDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed to save interest')));
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerYellow,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(backgroundColor: AppColors.headerYellow, elevation: 0, leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _course == null && widget.courseId != null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(backgroundColor: AppColors.headerYellow, elevation: 0, leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context))),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), TextButton(onPressed: _loadCourse, child: const Text('Retry'))])),
      );
    }
    final c = _course;
    final title = c != null ? (c['course_title'] ?? '').toString() : 'UI/UX Design Course';
    final eligibility = c != null ? (c['eligibility'] ?? '').toString() : 'Graduate / IT students';
    final duration = c != null ? (c['duration'] ?? '').toString() : '6 – 10 Months';
    final mode = c != null ? (c['mode'] ?? '').toString() : 'Offline / Online';
    final certification = c != null ? (c['certification'] ?? '').toString() : '';
    final user = c != null ? c['user'] : null;
    final userName = user is Map ? (user['name'] ?? '').toString() : 'MIT World Peace University';
    final userEmail = user is Map ? (user['email'] ?? '').toString() : '';
    final userPhone = user is Map ? (user['phone'] ?? '').toString() : '';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Course Details', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBanner(context),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 22)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    eligibility.isNotEmpty ? eligibility : 'UI/UX Design focuses on creating user-friendly, visually appealing, and functional digital experiences.',
                    style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle(context, 'Duration'),
                  Text(duration.isEmpty ? '—' : duration, style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle(context, 'Mode'),
                  Text(mode.isEmpty ? '—' : mode, style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle(context, 'Eligibility'),
                  Text(eligibility.isEmpty ? '—' : eligibility, style: AppTextStyles.bodyMedium(context)),
                  if (certification.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _sectionTitle(context, 'Certification'),
                    Text(certification, style: AppTextStyles.bodyMedium(context)),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _sectionTitle(context, 'Course hosted by'),
                  _hostedByCard(context, userName),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle(context, 'Contact Person Details'),
                  _contactCard(context, userName, userPhone, userEmail),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _interestSent ? null : _onShowInterest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                      ),
                      child: Text(_interestSent ? 'Interest sent' : 'Show interest'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return ClipRRect(
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Image.asset(
          AppAssets.event1,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF5C6BC0),
            child: const Center(child: Icon(Icons.design_services, size: 64, color: AppColors.white)),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15)),
    );
  }

  Widget _hostedByCard(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              AppAssets.instituteProfile,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppColors.circleLightGrey,
                child: const Icon(Icons.school, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? '—' : name, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context, String name, String phone, String email) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _contactRow(context, 'Name', name.isEmpty ? '—' : name),
          const SizedBox(height: 8),
          _contactRow(context, 'Phone', phone.isEmpty ? '—' : phone),
          const SizedBox(height: 8),
          _contactRow(context, 'Email', email.isEmpty ? '—' : email),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text('$label:', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium(context))),
      ],
    );
  }
}
