import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';

/// Excel-style view of students after HR/Organization reviewed institute's sheet and reverted with status.
/// After row selection, institute can send data for campus confirmation.
class JobExcelResponsePage extends StatefulWidget {
  const JobExcelResponsePage({super.key});

  @override
  State<JobExcelResponsePage> createState() => _JobExcelResponsePageState();
}

class _JobExcelResponsePageState extends State<JobExcelResponsePage> {
  late List<Map<String, dynamic>> _rows;
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _rows = [
      {'name': 'Olivia Rhye', 'phone': '+91 9876543210', 'email': 'info@mitcoe.edu', 'degree': 'Mechanical Engineering', 'cgpa': '9.0', 'status': 'Completed'},
      {'name': 'Phoenix Baker', 'phone': '+91 9876543211', 'email': 'info@mitcoe.edu', 'degree': 'Mechanical Engineering', 'cgpa': '8.5', 'status': 'Completed'},
      {'name': 'Lana Steiner', 'phone': '+91 9876543212', 'email': 'info@mitcoe.edu', 'degree': 'Mechanical Engineering', 'cgpa': '8.0', 'status': 'Rejected'},
      {'name': 'Demi Wilkinson', 'phone': '+91 9876543213', 'email': 'info@mitcoe.edu', 'degree': 'Mechanical Engineering', 'cgpa': '9.0', 'status': 'Completed'},
      {'name': 'Candice Wu', 'phone': '+91 9876543214', 'email': 'info@mitcoe.edu', 'degree': 'Mechanical Engineering', 'cgpa': '7.5', 'status': 'Rejected'},
    ];
    _selected = List<bool>.filled(_rows.length, true);
  }

  int get _selectedCount => _selected.where((v) => v).length;

  void _goToCampusConfirmation(String jobTitle, Map<String, dynamic> routeMap) {
    final students = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      if (_selected[i]) {
        students.add(Map<String, dynamic>.from(_rows[i]));
      }
    }
    if (students.isEmpty) return;
    Navigator.pushNamed(
      context,
      AppRoutes.jobCampusConfirmation,
      arguments: {
        'jobId': routeMap['jobId'],
        'jobTitle': jobTitle,
        'students': students,
      },
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};
    final jobTitle = (map['jobTitle'] ?? 'Campus Drive for Designer').toString();
    final count = map['applicantCount'] is int ? map['applicantCount'] as int : _rows.length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Student list', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.headerYellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count Applicants',
                    style: AppTextStyles.bodySmall(context).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(AppColors.white),
                  dataRowMinHeight: 48,
                  headingTextStyle: AppTextStyles.bodySmall(context).copyWith(fontWeight: FontWeight.w700),
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
                  rows: List.generate(_rows.length, (i) {
                    final r = _rows[i];
                    final zebra = i.isEven ? AppColors.white : const Color(0xFFF5F5F5);
                    final status = r['status'].toString();
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
                                  value: _selected[i],
                                  onChanged: (v) => setState(() => _selected[i] = v ?? false),
                                  activeColor: AppColors.applicantsGreen,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('${i + 1}'),
                            ],
                          ),
                        ),
                        DataCell(SizedBox(width: 100, child: Text(r['name'].toString(), overflow: TextOverflow.ellipsis))),
                        DataCell(Text(r['phone'].toString())),
                        DataCell(SizedBox(width: 120, child: Text(r['email'].toString(), overflow: TextOverflow.ellipsis))),
                        DataCell(SizedBox(width: 140, child: Text(r['degree'].toString(), overflow: TextOverflow.ellipsis))),
                        DataCell(Text(r['cgpa'].toString())),
                        DataCell(
                          Text(
                            status,
                            style: TextStyle(
                              color: status == 'Rejected' ? Colors.red : AppColors.applicantsGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                        )),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Text(
              'Select students, then send preferred campus dates for HR/Organization confirmation.',
              style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 8, AppSpacing.screenHorizontal, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedCount > 0)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _goToCampusConfirmation(jobTitle, map),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Send for campus confirmation ($_selectedCount)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (_selectedCount == 0)
                Text(
                  'Select at least one student to continue.',
                  style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
