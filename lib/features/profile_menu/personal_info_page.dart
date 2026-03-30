import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/signup_args.dart';
import '../../core/api/api_config.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/profile_api.dart';
import '../../widgets/app_primary_button.dart';

/// Personal Info — full profile completion form (job seeker / institute).
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _profileApi = ProfileApi();
  bool _loading = true;
  bool _saving = false;
  String? _userRole;
  String _profileImageUrl = '';

  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _addressController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _streamController = TextEditingController();
  final _collegeController = TextEditingController();
  final _universityController = TextEditingController();
  final _experienceLevelController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _employmentTypeController = TextEditingController();
  final _durationFromController = TextEditingController();
  final _durationToController = TextEditingController();
  final _skillsController = TextEditingController();

  String? _state;
  String? _city;

  static const List<String> _states = [
    'Maharashtra',
    'Karnataka',
    'Gujarat',
    'Tamil Nadu',
    'Delhi',
    'Telangana',
    'West Bengal',
  ];

  static const Map<String, List<String>> _citiesByState = {
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru', 'Hubballi'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi'],
    'Telangana': ['Hyderabad', 'Warangal'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur'],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _qualificationController.dispose();
    _streamController.dispose();
    _collegeController.dispose();
    _universityController.dispose();
    _experienceLevelController.dispose();
    _companyNameController.dispose();
    _employmentTypeController.dispose();
    _durationFromController.dispose();
    _durationToController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  String get _displayImageUrl {
    if (_profileImageUrl.isEmpty) return '';
    if (_profileImageUrl.startsWith(RegExp(r'^https?://'))) return _profileImageUrl;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (_profileImageUrl.startsWith('/') ? '' : '/') + _profileImageUrl;
  }

  bool get _isInstitute => _userRole == 'institute';

  Future<void> _load() async {
    setState(() => _loading = true);
    final role = await AuthStorage.getUserRole();
    _userRole = role?.trim().toLowerCase();
    if (_userRole == 'job_seeker') {
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.profileForm,
          arguments: const SignUpArgs(phone: '', role: 'job_seeker', isEditProfile: true),
        );
      });
      return;
    }
    if (_userRole == 'institute') {
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.profileForm,
          arguments: const SignUpArgs(phone: '', role: 'institute', isEditProfile: true),
        );
      });
      return;
    }
    final res = await _profileApi.getProfile();
    if (!mounted) return;
    setState(() => _loading = false);
    if (!res.isOk || res.data is! Map) return;
    final data = res.data as Map;
    final user = data['data'];
    if (user is! Map) return;

    final imageUrl = (user['image'] ?? '').toString().trim();
    _profileImageUrl = imageUrl;

    _nameController.text = (user['name'] ?? '').toString();
    _aboutController.text = (user['bio'] ?? '').toString();
    _phoneController.text = (user['phone'] ?? '').toString();
    _emailController.text = (user['email'] ?? '').toString();

    final Map<String, dynamic> extra = _isInstitute
        ? (user['institute_profile'] is Map
            ? Map<String, dynamic>.from(user['institute_profile'] as Map)
            : {})
        : (user['job_seeker_profile'] is Map
            ? Map<String, dynamic>.from(user['job_seeker_profile'] as Map)
            : {});

    _jobTitleController.text = (extra['job_title'] ?? '').toString();
    _addressController.text = (extra['address'] ?? '').toString();
    _qualificationController.text = (extra['qualification'] ?? extra['education'] ?? '').toString();
    _streamController.text = (extra['stream'] ?? extra['specialization'] ?? '').toString();
    _collegeController.text = (extra['college_name'] ?? '').toString();
    _universityController.text = (extra['university_board'] ?? extra['university'] ?? '').toString();
    _experienceLevelController.text = (extra['experience_level'] ?? '').toString();
    _companyNameController.text = (extra['company_name'] ?? '').toString();
    _employmentTypeController.text = (extra['employment_type'] ?? '').toString();
    _durationFromController.text = (extra['duration_from'] ?? '').toString();
    _durationToController.text = (extra['duration_to'] ?? '').toString();
    _skillsController.text = (extra['skills'] ?? '').toString();

    final st = (extra['state'] ?? '').toString().trim();
    final ct = (extra['city'] ?? '').toString().trim();
    if (st.isNotEmpty && _states.contains(st)) {
      _state = st;
    }
    if (ct.isNotEmpty) {
      _city = ct;
    }

    setState(() {});
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final userBody = <String, dynamic>{
      'name': _nameController.text.trim(),
      'bio': _aboutController.text.trim(),
    };
    if (_phoneController.text.trim().isNotEmpty) {
      userBody['phone'] = _phoneController.text.trim();
    }
    if (_emailController.text.trim().isNotEmpty) {
      userBody['email'] = _emailController.text.trim();
    }

    final profilePayload = <String, dynamic>{
      'address': _addressController.text.trim(),
      'state': _state ?? '',
      'city': _city ?? '',
      'job_title': _jobTitleController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'stream': _streamController.text.trim(),
      'college_name': _collegeController.text.trim(),
      'university_board': _universityController.text.trim(),
      'experience_level': _experienceLevelController.text.trim(),
      'company_name': _companyNameController.text.trim(),
      'employment_type': _employmentTypeController.text.trim(),
      'duration_from': _durationFromController.text.trim(),
      'duration_to': _durationToController.text.trim(),
      'skills': _skillsController.text.trim(),
    };

    final putBody = _isInstitute
        ? <String, dynamic>{'institute_profile': profilePayload}
        : <String, dynamic>{'job_seeker_profile': profilePayload};

    final r1 = await _profileApi.updateUserProfile(userBody);
    final r2 = await _profileApi.updateProfile(putBody);
    if (!mounted) return;
    setState(() => _saving = false);

    if (r1.isOk && r2.isOk) {
      await AuthStorage.setUserName(_nameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      }
    } else {
      final err = r2.error ?? r1.error ?? 'Update failed';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    XFile? xFile;
    try {
      final picker = ImagePicker();
      xFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.toString()), behavior: SnackBarBehavior.floating),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (xFile == null || !mounted) return;
    setState(() => _loading = true);
    final res = await _profileApi.uploadProfileImage(File(xFile.path));
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isOk && res.data != null) {
      dynamic body = res.data;
      if (body is Map && body['data'] is Map) body = body['data'];
      final url = body is Map ? body['image']?.toString() : null;
      if (url != null && url.isNotEmpty) {
        setState(() => _profileImageUrl = url);
        await AuthStorage.setProfileImageUrl(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo updated'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  List<String> get _cityOptions {
    if (_state == null || !_citiesByState.containsKey(_state)) {
      return _citiesByState[_states.first] ?? [];
    }
    return _citiesByState[_state]!;
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
        title: Text('Personal Info', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _buildAvatar(context)),
                        const SizedBox(height: AppSpacing.xl),
                        _labeledField(context, label: 'Name', child: _shadowTextField(controller: _nameController)),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Job Title / Role',
                          child: _shadowTextField(controller: _jobTitleController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Address',
                          child: _shadowTextField(
                            controller: _addressController,
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labelRow(context, 'Location (State & City)'),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _stateDropdown(context)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: _cityDropdown(context)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'About Us',
                          child: _shadowTextField(controller: _aboutController, maxLines: 4),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Phone',
                          child: _shadowTextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Email',
                          child: _shadowTextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Qualification',
                          child: _shadowTextField(controller: _qualificationController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Stream / Specialization',
                          child: _shadowTextField(controller: _streamController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'College Name',
                          child: _shadowTextField(controller: _collegeController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'University / Board',
                          child: _shadowTextField(controller: _universityController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Experience Level',
                          child: _shadowTextField(controller: _experienceLevelController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Company Name',
                          child: _shadowTextField(controller: _companyNameController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Employment Type',
                          child: _shadowTextField(controller: _employmentTypeController),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labelRow(context, 'Duration'),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _labeledField(
                                context,
                                label: 'From',
                                child: _shadowTextField(controller: _durationFromController),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _labeledField(
                                context,
                                label: 'To',
                                child: _shadowTextField(controller: _durationToController),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _labeledField(
                          context,
                          label: 'Skills',
                          child: _shadowTextField(controller: _skillsController, maxLines: 4),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                      AppSpacing.screenHorizontal,
                      AppSpacing.lg,
                    ),
                    child: AppPrimaryButton(
                      label: _saving ? 'Saving…' : 'Update Profile',
                      onPressed: _saving ? null : _submit,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: _profileImageUrl.isNotEmpty
                ? Image.network(
                    _displayImageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderAvatar(),
                  )
                : Image.asset(
                    AppAssets.dummyProfile,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderAvatar(),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inputBorder, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.circleLightGrey,
      child: const Icon(Icons.person, size: 48, color: AppColors.textSecondary),
    );
  }

  Widget _stateDropdown(BuildContext context) {
    return _shadowField(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text('State', style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
            value: _state != null && _states.contains(_state) ? _state : null,
            items: _states
                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _state = v;
                final cities = _cityOptions;
                _city = (cities.contains(_city) ? _city : null);
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _cityDropdown(BuildContext context) {
    final opts = _cityOptions;
    return _shadowField(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text('City', style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
            value: _city != null && opts.contains(_city) ? _city : null,
            items: opts
                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _city = v),
          ),
        ),
      ),
    );
  }

  Widget _labelRow(BuildContext context, String label) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.8)),
      ],
    );
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _labelRow(context, label),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _shadowField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _shadowTextField({
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return _shadowField(
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMedium(context),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: null,
        ),
      ),
    );
  }
}
