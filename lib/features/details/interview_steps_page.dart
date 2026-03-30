import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/interview_flow_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Multi-step interview rounds after campus confirmation — table of candidates from the
/// submitted Excel; each **Done** carries forward only selected students (HR/org flow).
class InterviewStepsPage extends StatefulWidget {
  const InterviewStepsPage({super.key});

  @override
  State<InterviewStepsPage> createState() => _InterviewStepsPageState();
}

class _InterviewStepsPageState extends State<InterviewStepsPage> {
  bool _loading = true;
  bool _flowAlreadyCompleted = false;
  int? _jobId;
  String _jobTitle = 'Campus Drive for Designer';
  int _stepIndex = 0;
  List<Map<String, dynamic>> _students = [];
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};
    final jid = map['jobId'];
    _jobId = jid is int ? jid : int.tryParse('$jid');

    if (map['students'] is List && (map['students'] as List).isNotEmpty) {
      _jobTitle = (map['jobTitle'] ?? _jobTitle).toString();
      _stepIndex = map['stepIndex'] is int ? map['stepIndex'] as int : int.tryParse('${map['stepIndex']}') ?? 0;
      _students = (map['students'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _stepIndex = _stepIndex.clamp(0, InterviewFlowStorage.totalSteps - 1);
      _selected = List<bool>.filled(_students.length, true);
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (_jobId != null) {
      await InterviewFlowStorage.init();
      final snap = await InterviewFlowStorage.load(_jobId!);
      if (snap != null) {
        if (snap.flowComplete) {
          if (mounted) {
            setState(() {
              _loading = false;
              _flowAlreadyCompleted = true;
              _students = [];
              _selected = [];
            });
          }
          return;
        }
        if (snap.students.isNotEmpty) {
          _jobTitle = snap.jobTitle.isNotEmpty ? snap.jobTitle : _jobTitle;
          _stepIndex = snap.stepIndex.clamp(0, InterviewFlowStorage.totalSteps - 1);
          _students = snap.students;
          _selected = List<bool>.filled(_students.length, true);
          if (mounted) setState(() => _loading = false);
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _students = [];
        _selected = [];
      });
    }
  }

  String get _stepLabel {
    final n = _stepIndex + 1;
    final title = InterviewFlowStorage.stepTitles[_stepIndex.clamp(0, InterviewFlowStorage.stepTitles.length - 1)];
    return 'Step $n - $title';
  }

  bool get _isLastStep => _stepIndex >= InterviewFlowStorage.totalSteps - 1;

  String? get _proceedHint {
    if (_isLastStep) return null;
    return 'Proceed For Step-${_stepIndex + 2}';
  }

  Future<void> _onDone() async {
    final selected = <Map<String, dynamic>>[];
    for (var i = 0; i < _students.length; i++) {
      if (i < _selected.length && _selected[i]) {
        selected.add(Map<String, dynamic>.from(_students[i]));
      }
    }
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one candidate'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_isLastStep) {
      if (_jobId != null) {
        await InterviewFlowStorage.markFlowComplete(_jobId!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview step completed.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
      return;
    }

    if (_jobId == null) {
      setState(() {
        _stepIndex++;
        _students = selected;
        _selected = List<bool>.filled(_students.length, true);
      });
      return;
    }

    await InterviewFlowStorage.advanceStep(_jobId!, selected);
    final snap = await InterviewFlowStorage.load(_jobId!);
    if (!mounted) return;
    if (snap != null) {
      setState(() {
        _stepIndex = snap.stepIndex.clamp(0, InterviewFlowStorage.totalSteps - 1);
        _students = snap.students;
        _selected = List<bool>.filled(_students.length, true);
      });
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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Interview Steps', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: AppColors.textPrimary)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _flowAlreadyCompleted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Interview steps for this job are already completed.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : _students.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'No candidates for this step. Complete campus confirmation first or open from Job Details.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.sm),
                      child: Text(
                        _stepLabel,
                        style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _jobTitle,
                              style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.headerYellow.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_students.length} Applicants',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(child: _buildExcelTable(context)),
                    if (_proceedHint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          _proceedHint!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    const Divider(height: 1),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 12, AppSpacing.screenHorizontal, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _onDone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Excel-style sheet (same columns as campus confirmation / student list).
  Widget _buildExcelTable(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(AppColors.white),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 52,
            headingTextStyle: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
            columns: const [
              DataColumn(label: Text('Sr.No')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Phone No')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Degree/Course')),
              DataColumn(label: Text('CGPA')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: List.generate(_students.length, (i) {
              final r = _students[i];
              final zebra = i.isEven ? AppColors.white : const Color(0xFFF5F5F5);
              final status = _statusText(r);
              final sel = i < _selected.length ? _selected[i] : false;
              return DataRow(
                color: WidgetStateProperty.all(zebra),
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: sel,
                            onChanged: (v) => setState(() {
                              if (i < _selected.length) _selected[i] = v ?? false;
                            }),
                            activeColor: AppColors.applicantsGreen,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${i + 1}.'),
                      ],
                    ),
                  ),
                  DataCell(SizedBox(width: 100, child: Text(_col(r, 'name'), overflow: TextOverflow.ellipsis))),
                  DataCell(Text(_col(r, 'phone', '+91 9876543210'))),
                  DataCell(SizedBox(width: 120, child: Text(_col(r, 'email', 'info@mitcoe.edu'), overflow: TextOverflow.ellipsis))),
                  DataCell(SizedBox(width: 140, child: Text(_col(r, 'degree', 'Mechanical Engineering'), overflow: TextOverflow.ellipsis))),
                  DataCell(Text(_col(r, 'cgpa', '9.0'))),
                  DataCell(
                    Text(
                      status,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(_actionCell(context)),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  String _col(Map<String, dynamic> r, String key, [String defaultValue = '']) {
    final v = r[key];
    if (v == null || v.toString().isEmpty) return defaultValue;
    return v.toString();
  }

  String _statusText(Map<String, dynamic> r) {
    final s = (r['status'] ?? 'Completed').toString().trim();
    if (s.isEmpty) return 'Completed';
    return s;
  }

  Color _statusColor(String status) {
    final t = status.toLowerCase();
    if (t.contains('reject')) return Colors.red;
    return AppColors.applicantsGreen;
  }

  /// Offer Letter step: orange **Offer Letter** chip + edit/delete; other steps: edit/delete only.
  Widget _actionCell(BuildContext context) {
    final isOfferStep = _stepIndex == InterviewFlowStorage.totalSteps - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOfferStep) ...[
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.white),
            label: const Text('Offer Letter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 4),
        ],
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}
