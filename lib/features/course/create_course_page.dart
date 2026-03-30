import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/api/courses_api.dart';
import '../../widgets/app_text_field.dart';

/// Screen 49–50: Course Form — opened from + on Courses screen. Title, Description, Duration, Mode, Eligibility, optional Contact/Location. Submit → POST /courses.
class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _modeController = TextEditingController();
  final _eligibilityController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _locationController = TextEditingController();
  final _coursesApi = CoursesApi();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _modeController.dispose();
    _eligibilityController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    setState(() => _submitting = true);
    final body = <String, dynamic>{
      'course_title': title,
      'duration': _durationController.text.trim().isEmpty ? null : _durationController.text.trim(),
      'eligibility': _eligibilityController.text.trim().isEmpty ? null : _eligibilityController.text.trim(),
      'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      'skills_covered': [],
    };
    final mode = _modeController.text.trim().toLowerCase();
    if (mode.isNotEmpty) {
      if (mode.contains('online')) {
        body['mode'] = 'online';
      } else if (mode.contains('offline')) {
        body['mode'] = 'offline';
      }
    }
    final res = await _coursesApi.createCourse(body);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.isOk) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course created')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed to create course')));
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Course Form', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUploadBanner(context),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Title:',
                hint: 'e.g. UI/UX Design Course',
                controller: _titleController,
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description:', style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Course description...',
                      hintStyle: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.textFieldBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Duration:', hint: 'e.g. 6 – 10 Months', controller: _durationController),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Mode:', hint: 'e.g. offline or online', controller: _modeController),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Eligibility:', hint: 'e.g. Graduate / IT students', controller: _eligibilityController),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Location:', hint: 'e.g. Pune', controller: _locationController),
              const SizedBox(height: AppSpacing.xl),
              Text('Contact Person details (optional):', style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Name:', hint: 'e.g. Rakesh Pawar', controller: _contactNameController),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Phone:', hint: 'e.g. +91 9876543210', keyboardType: TextInputType.phone, controller: _contactPhoneController),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Email:', hint: 'e.g. example@gmail.com', keyboardType: TextInputType.emailAddress, controller: _contactEmailController),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadius)),
                  ),
                  child: _submitting ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Text('Submit'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.textFieldBackground,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.inputBorder, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Upload Course Banner',
              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
