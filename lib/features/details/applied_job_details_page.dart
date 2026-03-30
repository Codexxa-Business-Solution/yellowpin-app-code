import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class AppliedJobDetailsPage extends StatelessWidget {
  const AppliedJobDetailsPage({super.key});

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
    final role = (map['role'] ?? 'Machine Operator').toString();
    final company = (map['company'] ?? 'ABC Company').toString();
    final location = (map['location'] ?? 'Pimpri, Pune').toString();
    final ctc = (map['ctc'] ?? '₹2.7 LPA/- Year').toString();

    const steps = [
      ('Application submitted', '17/05/25', '11:00 am', true),
      ('Reviewed by Force Motors team', '25/05/25', '09:00 am', true),
      ('Screening interview', '05/06/25', '11:00 am', true),
      ('Technical interview', '12/06/25', '10:00 am', true),
      ('Final HR interview', '21/06/25', '04:00 pm', true),
      ('Team matching', '29/06/25', '02:00 pm', false),
      ('Offer letter', 'Not yet', '', false),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Applied Job Details', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.circleLightGrey, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18)),
                      Text(company, style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(ctc, style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 68),
              child: Text(location, style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Track Application', style: AppTextStyles.headingMedium(context).copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final s = steps[index];
                  final isDone = s.$4;
                  final isLast = index == steps.length - 1;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 34,
                          child: Column(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isDone ? AppColors.headerYellow : AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDone ? AppColors.headerYellow : AppColors.inputBorder,
                                    width: 2,
                                  ),
                                ),
                                child: isDone
                                    ? const Icon(Icons.check, size: 16, color: AppColors.white)
                                    : (!isLast
                                        ? const SizedBox.shrink()
                                        : const Icon(Icons.emoji_events_outlined, size: 15, color: AppColors.textSecondary)),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 1.5,
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    color: isDone ? AppColors.headerYellow : AppColors.inputBorder,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.$1, style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)),
                                const SizedBox(height: 3),
                                Text(
                                  s.$3.isEmpty ? s.$2 : '${s.$2}    ${s.$3}',
                                  style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Schedule Interview'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
