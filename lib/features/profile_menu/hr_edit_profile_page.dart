import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_config.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/profile_api.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';

class HrEditProfilePage extends StatefulWidget {
  const HrEditProfilePage({super.key});

  @override
  State<HrEditProfilePage> createState() => _HrEditProfilePageState();
}

class _HrEditProfilePageState extends State<HrEditProfilePage> {
  final _profileApi = ProfileApi();
  final _imagePicker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  int _step = 0;

  String _profileImageUrl = '';

  final _titleController = TextEditingController(text: 'Ms');
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _genderController = TextEditingController();

  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _employmentTypeController = TextEditingController();
  final _totalExperienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _industryController = TextEditingController();

  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  bool _hiringAuthorityConfirmed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _genderController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _employmentTypeController.dispose();
    _totalExperienceController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _industryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String get _displayImageUrl {
    if (_profileImageUrl.isEmpty) return '';
    if (_profileImageUrl.startsWith(RegExp(r'^https?://')))
      return _profileImageUrl;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base +
        (_profileImageUrl.startsWith('/') ? '' : '/') +
        _profileImageUrl;
  }

  String get _fullName {
    return [
      _titleController.text.trim(),
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');
  }

  List<String> get _skillsList => _skillsController.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _profileApi.getProfile();
    if (!mounted) return;
    if (res.isOk && res.data is Map) {
      final data = (res.data as Map)['data'];
      if (data is Map) {
        final name = (data['name'] ?? '').toString().trim();
        final nameParts = name
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .toList();
        if (nameParts.isNotEmpty) {
          final first = nameParts.first;
          final last = nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : '';
          if (first.length <= 4 &&
              [
                'mr',
                'mrs',
                'ms',
                'dr',
              ].contains(first.toLowerCase().replaceAll('.', ''))) {
            _titleController.text = first;
            if (nameParts.length > 1) _firstNameController.text = nameParts[1];
            if (nameParts.length > 2)
              _lastNameController.text = nameParts.sublist(2).join(' ');
          } else {
            _firstNameController.text = first;
            _lastNameController.text = last;
          }
        }

        _phoneController.text = (data['phone'] ?? '').toString();
        _emailController.text = (data['email'] ?? '').toString();
        _bioController.text = (data['bio'] ?? '').toString();
        _profileImageUrl = (data['image'] ?? '').toString().trim();

        final hr = data['hr_profile'];
        if (hr is Map) {
          _jobTitleController.text = (hr['job_title'] ?? '').toString();
          _companyController.text = (hr['company_name'] ?? '').toString();
          _employmentTypeController.text =
              (hr['employment_type'] ?? hr['designation'] ?? '').toString();
          _totalExperienceController.text = (hr['total_experience'] ?? '')
              .toString();
          _educationController.text = (hr['education_details'] ?? '')
              .toString();
          final rawSkills = hr['skills'];
          if (rawSkills is List) {
            _skillsController.text = rawSkills
                .map((e) => e.toString())
                .join(', ');
          } else {
            _skillsController.text = (rawSkills ?? '').toString();
          }
          _industryController.text = (hr['industry_type'] ?? '').toString();
          _genderController.text = (hr['gender'] ?? '')
              .toString()
              .toLowerCase();
          _stateController.text = (hr['state'] ?? '').toString();
          _cityController.text = (hr['city'] ?? '').toString();
          _hiringAuthorityConfirmed = hr['hiring_authority_confirmed'] == true;
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _saving = true);
    final res = await _profileApi.uploadProfileImage(File(file.path));
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.isOk && res.data != null) {
      dynamic body = res.data;
      if (body is Map && body['data'] is Map) body = body['data'];
      final url = body is Map ? body['image']?.toString() : null;
      if (url != null && url.isNotEmpty) {
        setState(() => _profileImageUrl = url);
        await AuthStorage.setProfileImageUrl(url);
      }
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _genderController.text.trim().isEmpty) {
        _showMessage('Please fill all required details in step 1');
        return false;
      }
    } else if (step == 1) {
      if (_jobTitleController.text.trim().isEmpty ||
          _companyController.text.trim().isEmpty ||
          _employmentTypeController.text.trim().isEmpty ||
          _totalExperienceController.text.trim().isEmpty ||
          _industryController.text.trim().isEmpty) {
        _showMessage('Please fill all required details in step 2');
        return false;
      }
    } else if (_stateController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      _showMessage('Please select state and city');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validateStep(2) || !_validateStep(1) || !_validateStep(0)) return;
    setState(() => _saving = true);
    final userRes = await _profileApi.updateUserProfile({
      'name': _fullName,
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty)
        'phone': _phoneController.text.trim(),
    });
    final hrRes = await _profileApi.updateProfile({
      'job_title': _jobTitleController.text.trim(),
      'company_name': _companyController.text.trim(),
      'employment_type': _employmentTypeController.text.trim(),
      'total_experience':
          int.tryParse(_totalExperienceController.text.trim()) ?? 0,
      'education_details': _educationController.text.trim(),
      'skills': _skillsList,
      'industry_type': _industryController.text.trim(),
      'gender': _genderController.text.trim(),
      'state': _stateController.text.trim(),
      'city': _cityController.text.trim(),
      'hiring_authority_confirmed': _hiringAuthorityConfirmed,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (userRes.isOk && hrRes.isOk) {
      await AuthStorage.setUserName(_fullName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
      return;
    }
    _showMessage(hrRes.error ?? userRes.error ?? 'Update failed');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step -= 1);
              return;
            }
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    if (_step == 0) ..._stepOne(context),
                    if (_step == 1) ..._stepTwo(),
                    if (_step == 2) ..._stepThree(context),
                    AppPrimaryButton(
                      label: _saving
                          ? 'Saving…'
                          : (_step == 2 ? 'Update Profile' : 'Next'),
                      onPressed: _saving
                          ? null
                          : () {
                              if (!_validateStep(_step)) return;
                              if (_step < 2) {
                                setState(() => _step += 1);
                              } else {
                                _save();
                              }
                            },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _stepOne(BuildContext context) {
    return [
      // Text(
      //   'Your profile helps you discover new people and opportunities',
      //   style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18),
      // ),
      const SizedBox(height: AppSpacing.xl),
      Center(
        child: GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.textFieldBackground,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_displayImageUrl)
                    : null,
                child: _profileImageUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.headerYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Row(
        children: [
          Expanded(
            child: _SearchableField(
              value: _titleController.text,
              hint: 'Title',
              options: const ['Mr', 'Mrs', 'Ms', 'Dr'],
              onSelected: (v) => setState(() => _titleController.text = v),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppTextField(
              label: 'First Name',
              hint: 'First name',
              controller: _firstNameController,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: 'Last Name',
        hint: 'Last name',
        controller: _lastNameController,
      ),
      const SizedBox(height: AppSpacing.lg),
      _readOnlyField(context, 'Phone', _phoneController.text),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: 'Email',
        hint: 'you@example.com',
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: 'Bio',
        hint: 'Write your bio',
        controller: _bioController,
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('Gender', style: AppTextStyles.bodyMedium(context)),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: ['Male', 'Female', 'Other']
            .map(
              (g) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _genderController.text = g.toLowerCase(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: _genderController.text == g.toLowerCase()
                            ? AppColors.headerYellow
                            : AppColors.textFieldBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Text(
                        g,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  List<Widget> _stepTwo() {
    return [
      AppTextField(
        label: null,
        hint: 'Most recent job title',
        controller: _jobTitleController,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: null,
        hint: 'Most recent company',
        controller: _companyController,
      ),
      const SizedBox(height: AppSpacing.lg),
      _SearchableField(
        value: _employmentTypeController.text,
        hint: 'Employment type',
        options: const [
          'Full-time',
          'Part-time',
          'Contract',
          'Internship',
          'Freelance',
        ],
        onSelected: (v) => setState(() => _employmentTypeController.text = v),
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: null,
        hint: 'Total experience',
        controller: _totalExperienceController,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: null,
        hint: 'Education details',
        controller: _educationController,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: null,
        hint: 'Skills (comma separated)',
        controller: _skillsController,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: null,
        hint: 'Industry type',
        controller: _industryController,
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  List<Widget> _stepThree(BuildContext context) {
    return [
      Text(
        "Let's confirm your location",
        style: AppTextStyles.headingLarge(context).copyWith(fontSize: 24),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Get noticed by recruiters in your area.',
        style: AppTextStyles.bodyMedium(
          context,
        ).copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.xxl),
      _SearchableField(
        value: _stateController.text,
        hint: 'State',
        options: _stateCityMap.keys.toList(),
        onSelected: (value) {
          setState(() {
            _stateController.text = value;
            _cityController.clear();
          });
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      _SearchableField(
        value: _cityController.text,
        hint: 'City',
        options: _stateCityMap[_stateController.text] ?? const <String>[],
        onSelected: (value) => setState(() => _cityController.text = value),
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        children: [
          Checkbox(
            value: _hiringAuthorityConfirmed,
            onChanged: (v) =>
                setState(() => _hiringAuthorityConfirmed = v ?? false),
            activeColor: AppColors.headerYellow,
          ),
          Expanded(
            child: Text(
              'I have hiring authority',
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
  }

  Widget _readOnlyField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.textFieldBackground,
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          child: Text(value, style: AppTextStyles.bodyMedium(context)),
        ),
      ],
    );
  }
}

class _SearchableField extends StatelessWidget {
  const _SearchableField({
    required this.value,
    required this.hint,
    required this.options,
    required this.onSelected,
  });

  final String value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => _SearchBottomSheet(options: options, title: hint),
        );
        if (selected != null && selected.isNotEmpty) onSelected(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.textFieldBackground,
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: value.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  const _SearchBottomSheet({required this.options, required this.title});

  final List<String> options;
  final String title;

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where(
          (item) => item.toLowerCase().contains(
            _searchController.text.trim().toLowerCase(),
          ),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: AppTextStyles.headingMedium(context)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search...',
              filled: true,
              fillColor: AppColors.textFieldBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return ListTile(
                  dense: true,
                  title: Text(item),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const Map<String, List<String>> _stateCityMap = {
  'Andhra Pradesh': [
    'Visakhapatnam',
    'Vijayawada',
    'Guntur',
    'Tirupati',
    'Nellore',
  ],
  'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Tawang'],
  'Assam': ['Guwahati', 'Dibrugarh', 'Silchar', 'Jorhat', 'Tezpur'],
  'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga'],
  'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Durg', 'Korba'],
  'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa'],
  'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
  'Haryana': ['Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Hisar'],
  'Himachal Pradesh': ['Shimla', 'Dharamshala', 'Solan', 'Mandi'],
  'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh'],
  'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru', 'Hubballi', 'Belagavi'],
  'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kannur'],
  'Madhya Pradesh': ['Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain'],
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
  'Manipur': ['Imphal', 'Thoubal', 'Bishnupur', 'Churachandpur'],
  'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Nongpoh'],
  'Mizoram': ['Aizawl', 'Lunglei', 'Champhai', 'Serchhip'],
  'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang'],
  'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Puri', 'Sambalpur'],
  'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Mohali'],
  'Rajasthan': ['Jaipur', 'Udaipur', 'Jodhpur', 'Kota', 'Bikaner'],
  'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing', 'Mangan'],
  'Tamil Nadu': [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
  ],
  'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam'],
  'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailashahar'],
  'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Noida', 'Varanasi', 'Agra'],
  'Uttarakhand': ['Dehradun', 'Haridwar', 'Haldwani', 'Roorkee'],
  'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Siliguri', 'Asansol'],
  'Andaman and Nicobar Islands': ['Port Blair'],
  'Chandigarh': ['Chandigarh'],
  'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa'],
  'Delhi': ['New Delhi', 'Dwarka', 'Rohini', 'Saket'],
  'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla'],
  'Ladakh': ['Leh', 'Kargil'],
  'Lakshadweep': ['Kavaratti', 'Agatti', 'Amini'],
  'Puducherry': ['Puducherry', 'Karaikal', 'Mahe', 'Yanam'],
};
