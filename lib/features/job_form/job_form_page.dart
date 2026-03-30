import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/api/jobs_api.dart';
import '../../widgets/app_text_field.dart';
import '../../core/api/api_config.dart';

/// Screens 33.0–33.3: Job Post form. CTC radio (Monthly/Yearly), Share With checkboxes. Submit → API create job.
class JobFormPage extends StatefulWidget {
  const JobFormPage({super.key, this.step = 1, this.jobId, this.initialJob});

  final int step;
  final int? jobId;
  final Map<String, dynamic>? initialJob;

  @override
  State<JobFormPage> createState() => _JobFormPageState();
}

class _JobFormPageState extends State<JobFormPage> {
  bool _ctcIsMonthly = true;
  // Defaults represent a "public" job (visible to colleges + job seekers).
  bool _shareWithCollege = true;
  bool _shareWithJobSeeker = true;
  bool _shareWithOther = false;
  final List<String> _selectedColleges = [];
  final _jobsApi = JobsApi();

  final _jobTitleController = TextEditingController();
  final _jobDescController = TextEditingController();
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _ctcController = TextEditingController();
  final _vacancyController = TextEditingController();
  final _locationController = TextEditingController();
  final _expiryDateController = TextEditingController();
  String _jobType = 'individual';
  String _employmentType = 'full_time';
  String _industryType = 'engineering';
  bool _submitting = false;
  DateTime? _expiryDate;
  String? _attachedFileName;
  String? _attachedFilePath;
  String? _attachedPreviewUrl;

  bool get _isEdit => widget.jobId != null;

  @override
  void initState() {
    super.initState();
    _prefillIfEditing();
  }

  void _prefillIfEditing() {
    final j = widget.initialJob;
    if (!_isEdit || j == null) return;

    _jobTitleController.text = (j['job_title'] ?? '').toString();
    _jobDescController.text = (j['job_description'] ?? '').toString();
    _educationController.text = (j['education_criteria'] ?? '').toString();

    final exp = j['experience_required_years'];
    final expInt = exp is int ? exp : int.tryParse(exp?.toString() ?? '');
    if (expInt != null && expInt > 0)
      _experienceController.text = '$expInt Years';

    final vacancy = j['vacancy_count'];
    final vacancyInt = vacancy is int
        ? vacancy
        : int.tryParse(vacancy?.toString() ?? '');
    if (vacancyInt != null && vacancyInt > 0)
      _vacancyController.text = vacancyInt.toString();

    _locationController.text = (j['location'] ?? '').toString();

    final jobType = (j['job_type'] ?? '').toString();
    final hiringType = (j['hiring_type'] ?? j['job_hiring_type'] ?? '')
        .toString();
    const hiringTypeValues = {'individual', 'bulk_hiring'};
    const employmentTypeValues = {
      'full_time',
      'part_time',
      'internship',
      'apprenticeship',
      'trainee',
      'experienced',
    };

    // Handle both correct mapping and older swapped records gracefully.
    if (hiringTypeValues.contains(hiringType)) {
      _jobType = hiringType;
    } else if (employmentTypeValues.contains(hiringType)) {
      _employmentType = hiringType;
    }
    if (employmentTypeValues.contains(jobType)) {
      _employmentType = jobType;
    } else if (hiringTypeValues.contains(jobType)) {
      _jobType = jobType;
    }

    final stream = (j['stream'] ?? '').toString();
    if (stream.isNotEmpty) _industryType = stream;

    final min = j['salary_min'];
    final minNum = min is num
        ? min.toDouble()
        : double.tryParse(min?.toString() ?? '');
    if (minNum != null && minNum > 0) {
      final period = (j['salary_period'] ?? 'monthly').toString();
      _ctcIsMonthly = period != 'yearly';
      _ctcController.text = minNum.toStringAsFixed(
        minNum.truncateToDouble() == minNum ? 0 : 2,
      );
    }

    // Prefill expiry date (Post Validity) if backend has it.
    final expiry = j['expiry_date'];
    if (expiry != null) {
      final parsed = DateTime.tryParse(expiry.toString());
      if (parsed != null) {
        _expiryDate = parsed;
        _expiryDateController.text =
            '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
      }
    }

    // Prefill "Share With" checkboxes from visibility_type.
    final vis = (j['visibility_type'] ?? 'public').toString();
    if (vis == 'public') {
      _shareWithCollege = true;
      _shareWithJobSeeker = true;
    } else if (vis == 'individual') {
      _shareWithCollege = false;
      _shareWithJobSeeker = false;
    } else if (vis == 'specific_institute' || vis == 'multiple_institutes') {
      _shareWithCollege = true;
      _shareWithJobSeeker = false;
    }

    // If dedicated share_with_* flags are present, they override the defaults above.
    if (j.containsKey('share_with_college') &&
        j['share_with_college'] != null) {
      _shareWithCollege =
          j['share_with_college'] == true ||
          j['share_with_college'].toString() == '1';
    }
    if (j.containsKey('share_with_job_seeker') &&
        j['share_with_job_seeker'] != null) {
      _shareWithJobSeeker =
          j['share_with_job_seeker'] == true ||
          j['share_with_job_seeker'].toString() == '1';
    }
    if (j.containsKey('share_with_other') && j['share_with_other'] != null) {
      _shareWithOther =
          j['share_with_other'] == true ||
          j['share_with_other'].toString() == '1';
    }

    // Prefill attachment (file name + preview) if backend has stored one.
    final attachmentPath = (j['attachment_path'] ?? j['attachment'])
        ?.toString();
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      final parts = attachmentPath.split(RegExp(r'[\\/]+'));
      _attachedFileName = parts.isNotEmpty ? parts.last : attachmentPath;
      // Existing attachment is on the server; build a preview URL (for images).
      _attachedFilePath = null;
      final lower = attachmentPath.toLowerCase();
      if (lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.webp')) {
        // Backend serves attachments directly from /job-attachments/... (no /storage prefix).
        // Example working URL from you:
        // https://yellowpin.bizz-manager.com/job-attachments/80MDQYy4Afq4CbuJUDSZoWp7Z3lohAlnz3ahDpdg.jpg
        _attachedPreviewUrl = '${ApiConfig.baseUrl}/$attachmentPath';
      }
    }
  }

  bool _isImageFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _jobDescController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _ctcController.dispose();
    _vacancyController.dispose();
    _locationController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _expiryDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        setState(() {
          _attachedFileName = result.files.single.name;
          _attachedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
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
                decoration: const BoxDecoration(
                  color: AppColors.headerYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Job Posted\nSuccessfully !',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium(
                  context,
                ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
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

  void _showCollegePicker() {
    final stateController = TextEditingController();
    final cityController = TextEditingController();
    final collegeController = TextEditingController();
    List<String> selected = List.from(_selectedColleges);

    showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.borderRadiusMedium),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select State / City / Colleges',
                  style: AppTextStyles.headingMedium(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: stateController,
                  decoration: InputDecoration(
                    hintText: 'State',
                    hintStyle: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.textFieldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    hintText: 'City',
                    hintStyle: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.textFieldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: collegeController,
                  decoration: InputDecoration(
                    hintText: 'College name',
                    hintStyle: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.textFieldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () {
                    final state = stateController.text.trim();
                    final city = cityController.text.trim();
                    final college = collegeController.text.trim();
                    if (college.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter college name'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    final label = state.isNotEmpty || city.isNotEmpty
                        ? '${state.isNotEmpty ? state : ''}${state.isNotEmpty && city.isNotEmpty ? ', ' : ''}${city.isNotEmpty ? city : ''} – $college'
                        : college;
                    setSheetState(() {
                      selected.add(label);
                      collegeController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerYellow,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('Add College'),
                ),
                const SizedBox(height: AppSpacing.md),
                if (selected.isNotEmpty) ...[
                  Text('Selected:', style: AppTextStyles.bodyMedium(context)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: selected
                        .map(
                          (c) => Chip(
                            label: Text(
                              c,
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(fontSize: 11),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () =>
                                setSheetState(() => selected.remove(c)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      ),
    ).then((result) {
      if (result != null) {
        setState(
          () => _selectedColleges
            ..clear()
            ..addAll(result),
        );
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
    final ctcLabel = _ctcIsMonthly ? 'Per Month' : 'Per Year';
    final ctcHint = _ctcIsMonthly ? '₹25,000' : '₹2.7 LPA';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Job' : 'Job Post',
          style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _dropdownField(
                'Job Type:',
                ['Individual', 'Bulk Hiring'],
                ['individual', 'bulk_hiring'],
                _jobType,
                (v) => setState(() => _jobType = v ?? _jobType),
              ),
              const SizedBox(height: AppSpacing.lg),
              _dropdownField(
                'Employment Type:',
                [
                  'Full Time',
                  'Part Time',
                  'Internship',
                  'Apprenticeship',
                  'Trainee',
                  'Experienced',
                ],
                [
                  'full_time',
                  'part_time',
                  'internship',
                  'apprenticeship',
                  'trainee',
                  'experienced',
                ],
                _employmentType,
                (v) => setState(() => _employmentType = v ?? _employmentType),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Job Title:',
                hint: 'e.g. Site Engineer',
                controller: _jobTitleController,
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Description:',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _jobDescController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the job...',
                      hintStyle: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.textFieldBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _dropdownField(
                'Industry Type:',
                ['Engineering', 'IT', 'Manufacturing', 'Other'],
                ['engineering', 'it', 'manufacturing', ''],
                _industryType,
                (v) => setState(() => _industryType = v ?? ''),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Education:',
                hint: 'e.g. B.E., Diploma',
                controller: _educationController,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Experience:',
                hint: 'e.g. 1-2 years',
                controller: _experienceController,
              ),
              const SizedBox(height: AppSpacing.lg),
              // CTC with radio buttons
              Text('CTC', style: AppTextStyles.bodyMedium(context)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _ctcToggle(
                    'Monthly',
                    _ctcIsMonthly,
                    () => setState(() => _ctcIsMonthly = true),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ctcToggle(
                    'Yearly',
                    !_ctcIsMonthly,
                    () => setState(() => _ctcIsMonthly = false),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctcController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: ctcHint,
                        hintStyle: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.textFieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(ctcLabel, style: AppTextStyles.bodyMedium(context)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Total vacancies:',
                hint: 'e.g. 5',
                controller: _vacancyController,
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Post Validity:',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: _pickExpiryDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          hintText: 'Select date',
                          hintStyle: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.textFieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Job Location:',
                hint: 'e.g. Pune',
                controller: _locationController,
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attach document (Optional)',
                    style: AppTextStyles.bodyMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: _pickAttachment,
                    child: Container(
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.textFieldBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                        border: Border.all(
                          color: AppColors.inputBorder,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _attachedFileName ?? '[ Select File ]',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: _attachedFileName != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_attachedFileName != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    if (_attachedFilePath != null &&
                        _isImageFile(_attachedFileName!))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.file(
                            File(_attachedFilePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.textFieldBackground,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Flexible(
                                        child: Text(
                                          _attachedFileName!,
                                          style: AppTextStyles.bodySmall(
                                            context,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        ),
                      )
                    else if (_attachedPreviewUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.network(
                            _attachedPreviewUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.textFieldBackground,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Flexible(
                                        child: Text(
                                          _attachedFileName!,
                                          style: AppTextStyles.bodySmall(
                                            context,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
                          ),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _attachedFileName!,
                                style: AppTextStyles.bodySmall(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Share With checkboxes (Wrap to avoid overflow on narrow screens)
              Text('Share With:', style: AppTextStyles.bodyMedium(context)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _shareWithCollege,
                        onChanged: (v) =>
                            setState(() => _shareWithCollege = v ?? true),
                        activeColor: AppColors.headerYellow,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('College'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _shareWithJobSeeker,
                        onChanged: (v) =>
                            setState(() => _shareWithJobSeeker = v ?? false),
                        activeColor: AppColors.headerYellow,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('Job Seeker'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _shareWithOther,
                        onChanged: (v) =>
                            setState(() => _shareWithOther = v ?? false),
                        activeColor: AppColors.headerYellow,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('Other'),
                    ],
                  ),
                ],
              ),
              if (_shareWithCollege) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: _showCollegePicker,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.textFieldBackground,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select State / City / Colleges',
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down),
                          ],
                        ),
                        if (_selectedColleges.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: _selectedColleges
                                .map(
                                  (c) => Chip(
                                    label: Text(
                                      c,
                                      style: AppTextStyles.bodySmall(
                                        context,
                                      ).copyWith(fontSize: 11),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onDeleted: () => setState(
                                      () => _selectedColleges.remove(c),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    _submitting
                        ? (_isEdit ? 'Updating…' : 'Posting…')
                        : (_isEdit ? 'Update' : 'Submit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    List<String> labels,
    List<String> values,
    String currentValue,
    void Function(String?) onChanged,
  ) {
    final value = values.contains(currentValue) ? currentValue : values.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.textFieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          initialValue: value,
          items: List.generate(
            labels.length,
            (i) => DropdownMenuItem(value: values[i], child: Text(labels[i])),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _ctcToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.headerYellow
                    : AppColors.inputBorder,
                width: 2,
              ),
            ),
            child: selected
                ? const Center(
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: AppColors.headerYellow,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    final title = _jobTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Job Title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final ctcStr = _ctcController.text.trim().replaceAll(',', '');
    final ctc = double.tryParse(ctcStr);
    // Store exactly what the user entered as CTC (monthly or yearly),
    // do not convert yearly to monthly in the payload.
    final salary = (ctc != null && ctc > 0) ? ctc : null;
    final vacancy = int.tryParse(_vacancyController.text.trim());
    final expStr = _experienceController.text.trim();
    final expYears =
        int.tryParse(RegExp(r'\d+').firstMatch(expStr)?.group(0) ?? '') ?? 0;
    // Map "Share With" checkboxes to visibility_type used by backend.
    String visibilityType;
    if (_shareWithJobSeeker) {
      // Backend has no "job seeker only" mode; "public" is the closest,
      // and also covers the case when both College + Job Seeker are selected.
      visibilityType = 'public';
    } else if (_shareWithCollege) {
      // Without real institute IDs we cannot distinguish specific vs multiple,
      // but use multiple_institutes when any college is selected.
      visibilityType = _selectedColleges.length > 1
          ? 'multiple_institutes'
          : 'specific_institute';
    } else {
      visibilityType = 'individual';
    }

    final body = <String, dynamic>{
      'job_title': title,
      'job_type': _employmentType,
      'hiring_type': _jobType,
      'job_description': _jobDescController.text.trim().isEmpty
          ? null
          : _jobDescController.text.trim(),
      'education_criteria': _educationController.text.trim().isEmpty
          ? null
          : _educationController.text.trim(),
      'experience_required_years': expYears > 0 ? expYears : null,
      'salary_min': salary,
      'salary_max': salary,
      'salary_period': _ctcIsMonthly ? 'monthly' : 'yearly',
      'vacancy_count': vacancy ?? 1,
      'location': _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      'stream': _industryType.isEmpty ? null : _industryType,
      'visibility_type': visibilityType,
      // TODO: wire actual institute IDs when college selection is backed by real data.
      'visible_to_institute_ids': <int>[],
      'expiry_date': _expiryDate != null
          ? '${_expiryDate!.year.toString().padLeft(4, '0')}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}'
          : null,
      'share_with_college': _shareWithCollege,
      'share_with_job_seeker': _shareWithJobSeeker,
      'share_with_other': _shareWithOther,
    };
    final res = _isEdit
        ? await _jobsApi.updateJob(
            widget.jobId!,
            body,
            attachmentPath: _attachedFilePath,
          )
        : await _jobsApi.createJob(body, attachmentPath: _attachedFilePath);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.isOk) {
      if (_isEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showSuccessDialog();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.error ??
                (_isEdit ? 'Failed to update job' : 'Failed to post job'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
