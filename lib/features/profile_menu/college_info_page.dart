import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_primary_button.dart';

class CollegeInfoPage extends StatefulWidget {
  const CollegeInfoPage({super.key});

  @override
  State<CollegeInfoPage> createState() => _CollegeInfoPageState();
}

class _CollegeInfoPageState extends State<CollegeInfoPage> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _about = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _streams = TextEditingController();
  final _ugCourses = TextEditingController();
  final _pgCourses = TextEditingController();
  final _tpoName = TextEditingController(text: 'roshanpatil');
  String _state = 'State';
  String _city = 'City';

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _about.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _streams.dispose();
    _ugCourses.dispose();
    _pgCourses.dispose();
    _tpoName.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('College Info', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: AppColors.textPrimary)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerCard(context),
            const SizedBox(height: AppSpacing.md),
            _field(context, 'Name:', _name),
            _field(context, 'Address:', _address, maxLines: 3),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _dropdown(context, _state, ['State', 'Maharashtra', 'Gujarat'], (v) => setState(() => _state = v))),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _dropdown(context, _city, ['City', 'Pune', 'Mumbai'], (v) => setState(() => _city = v))),
              ],
            ),
            _field(context, 'About Us:', _about, maxLines: 4),
            _field(context, 'Phone', _phone, keyboardType: TextInputType.phone),
            _field(context, 'Official Email:', _email, keyboardType: TextInputType.emailAddress),
            _field(context, 'Website', _website, keyboardType: TextInputType.url),
            _field(context, 'Streams:', _streams, maxLines: 2),
            _field(context, 'UG Courses:', _ugCourses, maxLines: 2),
            _field(context, 'PG Courses:', _pgCourses, maxLines: 2),
            _field(context, 'TPO Name:', _tpoName),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Update Profile',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('College profile updated'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    return Container(
      height: 145,
      decoration: BoxDecoration(
        color: AppColors.circleLightGrey.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          ),
          Positioned(
            left: 18,
            bottom: -26,
            child: Stack(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.circleLightGrey,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 48, color: AppColors.textSecondary),
                ),
                Positioned(
                  right: 2,
                  bottom: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, TextEditingController c, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.bodyMedium(context)),
              const Spacer(),
              const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(BuildContext context, String value, List<String> values, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: values
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
