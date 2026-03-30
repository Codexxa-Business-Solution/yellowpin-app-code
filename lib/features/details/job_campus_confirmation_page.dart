import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/api/interview_flow_storage.dart';

/// After selecting students on Excel view — confirm preferred campus visit dates and send to HR/Org.
class JobCampusConfirmationPage extends StatefulWidget {
  const JobCampusConfirmationPage({super.key});

  @override
  State<JobCampusConfirmationPage> createState() => _JobCampusConfirmationPageState();
}

class _JobCampusConfirmationPageState extends State<JobCampusConfirmationPage> {
  final _searchController = TextEditingController();
  final List<DateTime> _dateOptions = [
    DateTime(2025, 12, 8),
    DateTime(2025, 12, 9),
    DateTime(2025, 12, 15),
    DateTime(2025, 12, 16),
  ];
  late Set<int> _selectedDateIndices;

  @override
  void initState() {
    super.initState();
    _selectedDateIndices = {2, 3};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
    final students = map['students'] is List ? List<Map<String, dynamic>>.from((map['students'] as List).map((e) => Map<String, dynamic>.from(e as Map))) : <Map<String, dynamic>>[];
    final q = _searchController.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? students
        : students.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            final phone = (s['phone'] ?? '').toString().toLowerCase();
            return name.contains(q) || phone.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Job Applications', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: AppColors.textPrimary)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search',
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: Row(
              children: [
                Expanded(
                  child: Text(jobTitle, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.headerYellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtered.length} Candidates',
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.white),
                  // Default dataRowMaxHeight is 48 (kMinInteractiveDimension); min must be <= max.
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
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
                  rows: List.generate(filtered.length, (i) {
                    final r = filtered[i];
                    final zebra = i.isEven ? AppColors.white : const Color(0xFFF5F5F5);
                    return DataRow(
                      color: WidgetStateProperty.all(zebra),
                      cells: [
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_box, size: 20, color: AppColors.applicantsGreen),
                            const SizedBox(width: 6),
                            Text('${i + 1}.'),
                          ],
                        )),
                        DataCell(SizedBox(width: 100, child: Text((r['name'] ?? '').toString(), overflow: TextOverflow.ellipsis))),
                        DataCell(Text((r['phone'] ?? '').toString())),
                        DataCell(SizedBox(width: 120, child: Text((r['email'] ?? '').toString(), overflow: TextOverflow.ellipsis))),
                        DataCell(SizedBox(width: 140, child: Text((r['degree'] ?? '').toString(), overflow: TextOverflow.ellipsis))),
                        DataCell(Text((r['cgpa'] ?? '').toString())),
                        DataCell(
                          Text(
                            (r['status'] ?? '').toString(),
                            style: TextStyle(
                              color: (r['status'] ?? '').toString() == 'Rejected' ? Colors.red : AppColors.applicantsGreen,
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text('Preferred Dates for Campus', style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)),
                ),
                Icon(Icons.calendar_today_outlined, size: 22, color: AppColors.textSecondary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: List.generate(_dateOptions.length, (i) {
                final selected = _selectedDateIndices.contains(i);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedDateIndices.remove(i);
                      } else {
                        _selectedDateIndices.add(i);
                      }
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.headerYellow : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.headerYellow, width: selected ? 0 : 1.5),
                    ),
                    child: Text(
                      _formatDate(_dateOptions[i]),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final payload = Map<String, dynamic>.from(map);
                    payload['jobTitle'] = jobTitle;
                    if (payload['students'] == null) {
                      payload['students'] = students;
                    }
                    final jid = payload['jobId'];
                    final jobId = jid is int ? jid : int.tryParse('$jid');
                    final rawList = payload['students'];
                    final list = rawList is List
                        ? rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                        : <Map<String, dynamic>>[];
                    if (jobId != null && list.isNotEmpty) {
                      await InterviewFlowStorage.saveAfterCampusConfirm(jobId, jobTitle, list);
                    }
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.campusConfirmationSent,
                      arguments: payload,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Campus Confirm'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
