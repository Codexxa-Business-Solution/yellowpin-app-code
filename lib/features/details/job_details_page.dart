import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/api/jobs_api.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/api_config.dart';
import '../../core/api/interview_flow_storage.dart';
import '../job_form/job_form_page.dart';

/// When backend is ready, set [JobDetailsPage] job payload `institute_excel_response_received: true`
/// (or `excel_response_received`) to control the excel button without demo mode.
const bool _kDemoShowInstituteExcelResponseButton = true;

/// Job Details — opened from My Jobs (Posted or Applied). Tabs: Job Info | Company Info. Data from GET /jobs/{id}.
class JobDetailsPage extends StatefulWidget {
  const JobDetailsPage({super.key, this.jobId});

  final int? jobId;

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  int _selectedTab = 0; // 0 = Job Info, 1 = Company Info
  final _jobsApi = JobsApi();
  Map<String, dynamic>? _job;
  bool _loading = true;
  String? _error;
  PlatformFile? _selectedResumeFile;

  /// CV/Resume for job seeker apply flow (PDF/DOC).
  PlatformFile? _jobSeekerCvFile;
  final TextEditingController _moreInfoController = TextEditingController();
  String? _userRole;

  /// Campus confirmation done locally; show **Interview Steps** until flow completed.
  bool _interviewStepsAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    if (widget.jobId != null) {
      _loadJob();
    } else {
      setState(() {
        _loading = false;
        _error = 'No job selected';
      });
    }
  }

  @override
  void dispose() {
    _moreInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final r = await AuthStorage.getUserRole();
    if (!mounted) return;
    setState(() => _userRole = r?.trim().toLowerCase());
  }

  bool get _isInstitute => _userRole == 'institute';

  /// Institute applied with Excel; HR/Org has reverted with reviewed sheet — show "View Excel" entry.
  bool get _showViewExcelWithResponseButton {
    if (!_isInstitute || _job == null) return false;
    final j = _job!;
    if (j['institute_excel_response_received'] == true) return true;
    if (j['excel_response_received'] == true) return true;
    if (j['org_excel_response_ready'] == true) return true;
    return _kDemoShowInstituteExcelResponseButton;
  }

  bool get _showInterviewStepsButton =>
      _isInstitute && widget.jobId != null && _interviewStepsAvailable;

  /// Extra bottom padding so fixed buttons don't cover scroll content.
  double get _jobInfoBottomPadding {
    if (!_isInstitute) return 90;
    var extra = 0.0;
    if (_showViewExcelWithResponseButton) extra += 58;
    if (_showInterviewStepsButton) extra += 58;
    return 90 + extra;
  }

  Future<void> _refreshInterviewStepsFlag() async {
    if (widget.jobId == null) return;
    final show = await InterviewFlowStorage.shouldShowInterviewStepsButton(
      widget.jobId!,
    );
    if (mounted) setState(() => _interviewStepsAvailable = show);
  }

  void _openExcelResponseView() {
    Navigator.pushNamed(
      context,
      AppRoutes.jobExcelResponse,
      arguments: {
        'jobId': widget.jobId,
        'jobTitle': _jobTitle.isEmpty ? 'Job' : _jobTitle,
        'companyName': _companyName,
        'applicantCount': 30,
      },
    ).then((_) => _refreshInterviewStepsFlag());
  }

  void _openInterviewSteps() {
    if (widget.jobId == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.interviewSteps,
      arguments: {'jobId': widget.jobId},
    ).then((_) => _refreshInterviewStepsFlag());
  }

  Future<void> _loadJob() async {
    if (widget.jobId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _jobsApi.getJob(widget.jobId!);
    if (!mounted) return;
    var interviewSteps = false;
    if (res.isOk) {
      interviewSteps =
          await InterviewFlowStorage.shouldShowInterviewStepsButton(
            widget.jobId!,
          );
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _interviewStepsAvailable = interviewSteps;
      if (res.isOk && res.data is Map) {
        _job = Map<String, dynamic>.from(res.data as Map);
      } else {
        _error = res.error ?? 'Failed to load job';
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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Job Details',
          style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (v) async {
              final jobId = widget.jobId;
              final job = _job;
              if (jobId == null) return;
              if (v == 'edit') {
                if (job == null) return;
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JobFormPage(step: 1, jobId: jobId, initialJob: job),
                  ),
                );
                if (updated == true) {
                  _loadJob();
                }
              } else if (v == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Job'),
                    content: const Text(
                      'Are you sure you want to delete this job? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final res = await _jobsApi.deleteJob(jobId);
                  if (!mounted) return;
                  if (res.isOk) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Job deleted successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.error ?? 'Failed to delete job'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Edit Job', style: AppTextStyles.bodyMedium(context)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Job',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(onPressed: _loadJob, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildJobSummaryCard(context),
                  _buildTabs(context),
                  _selectedTab == 0
                      ? _buildJobInfoContent(context)
                      : _buildCompanyInfoContent(context),
                  SizedBox(height: _jobInfoBottomPadding),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          8,
          AppSpacing.screenHorizontal,
          12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showViewExcelWithResponseButton) ...[
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openExcelResponseView,
                  icon: const Icon(Icons.table_chart_outlined, size: 20),
                  label: const Text('View Excel with Response'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(
                      color: AppColors.headerYellow,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_showInterviewStepsButton) ...[
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openInterviewSteps,
                  icon: const Icon(Icons.list_alt_outlined, size: 20),
                  label: const Text('Interview Steps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(
                      color: AppColors.headerYellow,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showApplyNowSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickResumeFile(VoidCallback refresh) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xls', 'xlsx', 'csv'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    _selectedResumeFile = result.files.single;
    refresh();
  }

  Future<void> _pickJobSeekerCv(VoidCallback refresh) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    _jobSeekerCvFile = result.files.single;
    refresh();
  }

  String _jobSeekerFileMeta(PlatformFile f) {
    final kb = (f.size / 1024).toStringAsFixed(0);
    final d = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour24 = d.hour;
    final h = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
    final ampm = hour24 >= 12 ? 'pm' : 'am';
    final mm = d.minute.toString().padLeft(2, '0');
    return '$kb Kb · ${d.day} ${months[d.month - 1]} ${d.year} at $h:$mm $ampm';
  }

  void _showApplyNowSheet() {
    if (_isInstitute) {
      _showInstituteApplyDialog();
    } else {
      _showJobSeekerApplyDialog();
    }
  }

  /// Job seeker: CV/Resume modal → [ApplicationSuccessPage] → Track job.
  void _showJobSeekerApplyDialog() {
    setState(() => _jobSeekerCvFile = null);
    _moreInfoController.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 24,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Add your CV/Resume to apply for a job',
                                style: AppTextStyles.bodyMedium(context)
                                    .copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: AppColors.inputBorder),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: AppColors.circleLightGrey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.business,
                                    color: AppColors.textSecondary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'You are applying for',
                                        style: AppTextStyles.bodySmall(context)
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                      Text(
                                        _companyName,
                                        style: AppTextStyles.headingMedium(
                                          context,
                                        ).copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        _location.isEmpty ? 'Pune' : _location,
                                        style: AppTextStyles.bodyMedium(context)
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (_jobSeekerCvFile == null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                    style: BorderStyle.solid,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFFAFAFA),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    ElevatedButton.icon(
                                      onPressed: () async => _pickJobSeekerCv(
                                        () => setModalState(() {}),
                                      ),
                                      icon: const Icon(Icons.upload, size: 18),
                                      label: const Text('Upload CV/Resume'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.headerYellow,
                                        foregroundColor: AppColors.textPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'or drag and drop your resume here.',
                                      style: AppTextStyles.bodySmall(context)
                                          .copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                    style: BorderStyle.solid,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFF8F8F8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          size: 40,
                                          color: Colors.red.shade400,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _jobSeekerCvFile!.name,
                                                style:
                                                    AppTextStyles.bodyMedium(
                                                      context,
                                                    ).copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _jobSeekerFileMeta(
                                                  _jobSeekerCvFile!,
                                                ),
                                                style:
                                                    AppTextStyles.bodySmall(
                                                      context,
                                                    ).copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => setModalState(
                                        () => _jobSeekerCvFile = null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.red.shade400,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Remove file',
                                            style: AppTextStyles.bodyMedium(
                                              context,
                                            ).copyWith(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'More Information',
                              style: AppTextStyles.headingMedium(
                                context,
                              ).copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _moreInfoController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Explain why you are the right person for this job',
                                  hintStyle: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _jobSeekerCvFile == null
                                    ? null
                                    : () {
                                        Navigator.pop(ctx);
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.applicationSuccess,
                                          arguments: {
                                            'company': _companyName,
                                            'role': _jobTitle.isEmpty
                                                ? 'Role'
                                                : _jobTitle,
                                            'location': _location,
                                            'ctc': _ctcText,
                                            'jobId': widget.jobId,
                                          },
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.black,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  disabledBackgroundColor: Colors.black38,
                                ),
                                child: const Text('Apply Now'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Institute: Excel student sheet apply (unchanged flow).
  void _showInstituteApplyDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Add your Student Data to apply for a job',
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(fontSize: 15),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: AppColors.inputBorder),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: AppColors.circleLightGrey,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You are applying for',
                                    style: AppTextStyles.bodySmall(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    _companyName,
                                    style: AppTextStyles.headingMedium(context),
                                  ),
                                  Text(
                                    _location.isEmpty ? 'Pune' : _location,
                                    style: AppTextStyles.bodyMedium(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (_selectedResumeFile == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 28,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.table_chart,
                                    size: 42,
                                    color: AppColors.applicantsGreen,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ElevatedButton.icon(
                                    onPressed: () async => _pickResumeFile(
                                      () => setModalState(() {}),
                                    ),
                                    icon: const Icon(
                                      Icons.upload_file,
                                      size: 18,
                                    ),
                                    label: const Text('Upload Excel Sheet'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.headerYellow,
                                      foregroundColor: AppColors.textPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'or drag and drop your resume here.',
                                    style: AppTextStyles.bodySmall(
                                      context,
                                    ).copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F5EE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFD8CFC0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.table_chart,
                                        size: 38,
                                        color: AppColors.applicantsGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedResumeFile!.name,
                                              style:
                                                  AppTextStyles.bodyMedium(
                                                    context,
                                                  ).copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${((_selectedResumeFile!.size / 1024).toStringAsFixed(0))} Kb',
                                              style:
                                                  AppTextStyles.bodySmall(
                                                    context,
                                                  ).copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => setModalState(
                                      () => _selectedResumeFile = null,
                                    ),
                                    child: Text(
                                      'Remove file',
                                      style: AppTextStyles.bodyMedium(
                                        context,
                                      ).copyWith(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'More Information',
                            style: AppTextStyles.headingMedium(
                              context,
                            ).copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _moreInfoController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText:
                                    'Explain why you are the right\nperson for this job',
                                hintStyle: AppTextStyles.bodyMedium(
                                  context,
                                ).copyWith(color: AppColors.textSecondary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.applicationSuccess,
                                  arguments: {
                                    'company': _companyName,
                                    'role': _jobTitle,
                                    'location': _location,
                                    'ctc': _ctcText,
                                    'jobId': widget.jobId,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.black,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Apply Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String get _jobTitle => (_job?['job_title'] ?? '').toString();
  String get _companyName {
    final user = _job?['user'];
    return user is Map ? (user['name'] ?? 'Company').toString() : 'Company';
  }

  String get _location => (_job?['location'] ?? '').toString();
  int get _vacancyCount =>
      _job?['vacancy_count'] is int ? _job!['vacancy_count'] as int : 1;
  int get _applicantsCount {
    final c = _job?['applications_count'];
    if (c is int) return c;
    final parsed = int.tryParse(c?.toString() ?? '');
    return parsed ?? 10;
  }

  String get _jobTypeFormatted {
    final t = (_job?['job_type'] ?? '').toString();
    if (t.isEmpty) return 'Full-time';
    return t
        .split('_')
        .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }

  String get _interviewMode {
    final m = (_job?['interview_mode'] ?? '').toString();
    if (m == 'offline' || m == 'on_site') return 'On-site';
    if (m == 'online') return 'Remote';
    if (m == 'campus') return 'Campus';
    return 'On-site';
  }

  String _daysAgo() {
    final createdAt = _job?['created_at'];
    if (createdAt == null) return '';
    try {
      final dt = DateTime.tryParse(createdAt.toString());
      if (dt == null) return '';
      final d = DateTime.now().difference(dt).inDays;
      if (d == 0) return 'Today';
      if (d == 1) return '1d';
      return '${d}d';
    } catch (_) {
      return '';
    }
  }

  String _fullProfileImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith(RegExp(r'^https?://'))) return url;
    final base = ApiConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (url.startsWith('/') ? '' : '/') + url;
  }

  Widget _buildJobSummaryCard(BuildContext context) {
    final vacancyText = _location.isEmpty
        ? 'Vacancies: $_vacancyCount'
        : '$_location (Vacancies: $_vacancyCount)';
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Builder(
                  builder: (context) {
                    final url = _fullProfileImageUrl(
                      AuthStorage.profileImageUrl,
                    );
                    if (url.isNotEmpty) {
                      return Image.network(
                        url,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.circleLightGrey,
                          child: const Icon(
                            Icons.business,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return Image.asset(
                      AppAssets.vacancyLogo1,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.circleLightGrey,
                        child: const Icon(
                          Icons.business,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _jobTitle.isEmpty ? 'Job' : _jobTitle,
                      style: AppTextStyles.headingMedium(
                        context,
                      ).copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _companyName,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vacancyText,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _daysAgo(),
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '$_applicantsCount applicants',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.applicantsGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.bookmark_border, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.headerYellow.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.headerYellow),
                ),
                child: Text(
                  _interviewMode,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.headerYellow),
                ),
                child: Text(
                  _jobTypeFormatted,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    Text(
                      'Job Info',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: _selectedTab == 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedTab == 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (_selectedTab == 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        height: 2,
                        width: 82,
                        decoration: BoxDecoration(
                          color: AppColors.headerYellow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    Text(
                      'Company Info',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: _selectedTab == 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedTab == 1
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (_selectedTab == 1) ...[
                      const SizedBox(height: 6),
                      Container(
                        height: 2,
                        width: 94,
                        decoration: BoxDecoration(
                          color: AppColors.headerYellow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _industryType => (_job?['stream'] ?? '').toString().isEmpty
      ? '—'
      : (_job!['stream'] as String)
            .split('_')
            .map(
              (s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}',
            )
            .join(' / ');
  String get _education =>
      (_job?['education_criteria'] ?? '').toString().trim().isEmpty
      ? '—'
      : (_job!['education_criteria'] as String);
  String get _experienceText {
    final y = _job?['experience_required_years'];
    if (y == null) return '—';
    final n = y is int ? y : int.tryParse(y.toString());
    if (n == null || n == 0) return 'Fresher';
    return n == 1 ? '1 year' : '$n years';
  }

  String get _ctcText {
    final min = _job?['salary_min'];
    final max = _job?['salary_max'];
    if (min == null && max == null) return '—';
    double? a = min is num
        ? (min as num).toDouble()
        : double.tryParse(min.toString());
    double? b = max is num
        ? (max as num).toDouble()
        : double.tryParse(max.toString());
    if (a == null && b == null) return '—';
    final lo = a ?? b!;
    final hi = b ?? a!;
    final period = (_job?['salary_period'] ?? 'monthly')
        .toString()
        .toLowerCase();
    String fmt(double v) {
      if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
      // Keep up to 2 decimals while avoiding trailing zeros.
      return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    }

    final amount = lo == hi ? '₹${fmt(lo)}' : '₹${fmt(lo)}–${fmt(hi)}';
    if (period == 'yearly') {
      return '$amount per year';
    }
    return '$amount per month';
  }

  String get _jobDescription =>
      (_job?['job_description'] ?? '').toString().trim();
  List<String> get _requiredSkills {
    final s = _job?['required_skills'];
    if (s is! List) return [];
    return s.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  Widget _buildJobInfoContent(BuildContext context) {
    final responsibilities = _listFromFields([
      'key_responsibilities',
      'responsibilities',
    ]);
    final facilities = _listFromFields([
      'facilities',
      'benefits',
      'facilities_and_others',
    ]);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, 'Industry Type', _industryType),
          _infoRow(context, 'Education', _education),
          _infoRow(context, 'Experience', _experienceText),
          _infoRow(context, 'CTC', _ctcText),
          _infoRow(
            context,
            'Location',
            _location.isEmpty ? '—' : _location,
            withDivider: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _JobDescriptionExpandable(description: _jobDescription),
          const SizedBox(height: AppSpacing.lg),
          if (_requiredSkills.isNotEmpty) ...[
            _sectionTitle(context, 'Skills Required'),
            ..._requiredSkills.map((s) => _bullet(context, s)),
          ],
          if (responsibilities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _sectionTitle(context, 'Key Responsibilities'),
            ...responsibilities.map((s) => _bullet(context, s)),
          ],
          if (facilities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _sectionTitle(context, 'Facilities and Others'),
            ...facilities.map((s) => _bullet(context, s)),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoContent(BuildContext context) {
    final user = _job?['user'];
    final email = user is Map ? (user['email'] ?? '').toString() : '';
    final phone = user is Map ? (user['phone'] ?? '').toString() : '';
    final about =
        (_job?['about_company'] ??
                _job?['company_description'] ??
                _job?['job_description'] ??
                '')
            .toString()
            .trim();
    final address = (_job?['company_address'] ?? _location).toString().trim();
    final employeeSize = (_job?['employee_size'] ?? _job?['company_size'] ?? '')
        .toString()
        .trim();
    final services = (_job?['services_products'] ?? _job?['services'] ?? '')
        .toString()
        .trim();
    final website = (_job?['company_website'] ?? '').toString().trim();
    final tpo = (_job?['tpo_name'] ?? '').toString().trim();
    final customers = _listFromFields(['customers', 'our_customers']);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'About Company'),
          Text(
            about.isEmpty ? _companyName : about,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Industry Type'),
          Text(_industryType, style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Address'),
          Text(
            address.isEmpty ? '—' : address,
            style: AppTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Employee Size'),
          Text(
            employeeSize.isEmpty ? '—' : employeeSize,
            style: AppTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Services/Products'),
          Text(
            services.isEmpty ? '—' : services,
            style: AppTextStyles.bodyMedium(context),
          ),
          if (customers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, 'Our Customers'),
            ...customers.map((c) => _bullet(context, c)),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          if (email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, 'Contact Email'),
            Text(email, style: AppTextStyles.bodyMedium(context)),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, 'Contact Phone'),
            Text(phone, style: AppTextStyles.bodyMedium(context)),
          ],
          if (website.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, 'Company Website:'),
            Text(
              website,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.linkBlue),
            ),
          ],
          if (tpo.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, 'TPO Name:'),
            Text(tpo, style: AppTextStyles.bodyMedium(context)),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    bool withDivider = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: withDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _listFromFields(List<String> keys) {
    for (final k in keys) {
      final v = _job?[k];
      if (v is List) {
        final list = v
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }
      if (v is String && v.trim().isNotEmpty) {
        final list = v
            .split(RegExp(r'[\n,]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }
    }
    return const [];
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: AppTextStyles.headingMedium(context).copyWith(fontSize: 15),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
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
}

class _JobDescriptionExpandable extends StatefulWidget {
  const _JobDescriptionExpandable({required this.description});

  final String description;

  @override
  State<_JobDescriptionExpandable> createState() =>
      _JobDescriptionExpandableState();
}

class _JobDescriptionExpandableState extends State<_JobDescriptionExpandable> {
  bool _expanded = false;
  static const int _maxCollapsed = 120;

  @override
  Widget build(BuildContext context) {
    final desc = widget.description;
    if (desc.isEmpty) {
      return Text(
        '—',
        style: AppTextStyles.bodyMedium(
          context,
        ).copyWith(color: AppColors.textSecondary),
      );
    }
    final shouldTruncate = desc.length > _maxCollapsed && !_expanded;
    final display = shouldTruncate
        ? '${desc.substring(0, _maxCollapsed)}...'
        : desc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        if (desc.length > _maxCollapsed)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Read less' : 'Read more',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.linkBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
