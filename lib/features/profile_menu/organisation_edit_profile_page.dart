import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

class OrganisationEditProfilePage extends StatefulWidget {
  const OrganisationEditProfilePage({super.key});

  @override
  State<OrganisationEditProfilePage> createState() => _OrganisationEditProfilePageState();
}

class _OrganisationEditProfilePageState extends State<OrganisationEditProfilePage> {
  final _profileApi = ProfileApi();
  final _imagePicker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _hasTradeName = false;
  bool _gstVerified = false;
  String _verifiedGstValue = '';
  String _profileImageUrl = '';

  final _orgCompanyNameController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _orgTradeNameController = TextEditingController();
  final _orgAddress1Controller = TextEditingController();
  final _orgAddress2Controller = TextEditingController();
  final _orgStateController = TextEditingController();
  final _orgCityController = TextEditingController();
  final _orgOfficialEmailController = TextEditingController();
  final _orgIndustryTypeController = TextEditingController();
  final _orgPanNoController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgWebsiteController = TextEditingController();
  final _orgHrPersonNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final Map<String, String> _orgDocumentNames = <String, String>{};

  @override
  void initState() {
    super.initState();
    _gstNumberController.addListener(() {
      final current = _gstNumberController.text.trim();
      if (_verifiedGstValue.isNotEmpty && current != _verifiedGstValue && _gstVerified) {
        setState(() => _gstVerified = false);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _orgCompanyNameController.dispose();
    _gstNumberController.dispose();
    _orgTradeNameController.dispose();
    _orgAddress1Controller.dispose();
    _orgAddress2Controller.dispose();
    _orgStateController.dispose();
    _orgCityController.dispose();
    _orgOfficialEmailController.dispose();
    _orgIndustryTypeController.dispose();
    _orgPanNoController.dispose();
    _orgPhoneController.dispose();
    _orgWebsiteController.dispose();
    _orgHrPersonNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _displayImageUrl {
    if (_profileImageUrl.isEmpty) return '';
    if (_profileImageUrl.startsWith(RegExp(r'^https?://'))) return _profileImageUrl;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (_profileImageUrl.startsWith('/') ? '' : '/') + _profileImageUrl;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _profileApi.getProfile();
    if (!mounted) return;
    if (res.isOk && res.data is Map) {
      final data = (res.data as Map)['data'];
      if (data is Map) {
        _orgOfficialEmailController.text = (data['email'] ?? '').toString().trim();
        _orgPhoneController.text = (data['phone'] ?? '').toString().trim();
        _profileImageUrl = (data['image'] ?? '').toString().trim();

        final org = data['organisation_profile'] ?? data['organization_profile'];
        if (org is Map) {
          _orgCompanyNameController.text = (org['company_name'] ?? '').toString();
          _gstNumberController.text = (org['gst_number'] ?? '').toString();
          _orgTradeNameController.text = (org['trade_name'] ?? '').toString();
          _hasTradeName = _orgTradeNameController.text.trim().isNotEmpty;
          final companyAddress = (org['company_address'] ?? '').toString().trim();
          if (companyAddress.contains(',')) {
            final parts = companyAddress.split(',');
            _orgAddress1Controller.text = parts.first.trim();
            _orgAddress2Controller.text = parts.sublist(1).join(',').trim();
          } else {
            _orgAddress1Controller.text = companyAddress;
          }
          _orgStateController.text = (org['state'] ?? '').toString();
          _orgCityController.text = (org['city'] ?? '').toString();
          _orgIndustryTypeController.text = (org['industry_type'] ?? '').toString();
          _orgPanNoController.text = (org['pan_no'] ?? '').toString();
          _orgWebsiteController.text = (org['company_website'] ?? '').toString();
          _orgHrPersonNameController.text =
              (org['authorized_signatory_name'] ?? org['hr_person_name'] ?? '').toString();
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _pickOrganizationLogo() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _saving = true);
    final res = await _profileApi.uploadProfileImage(File(picked.path));
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

  Future<void> _pickDocument(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _orgDocumentNames[key] = result.files.single.name);
  }

  void _verifyGstLocally() {
    final gst = _gstNumberController.text.trim();
    if (gst.isEmpty) {
      _showMessage('Please enter GST number');
      return;
    }
    setState(() {
      _gstVerified = true;
      _verifiedGstValue = gst;
    });
    _showMessage('GST Verified');
  }

  Future<void> _save() async {
    if (_orgCompanyNameController.text.trim().isEmpty ||
        _gstNumberController.text.trim().isEmpty ||
        _orgAddress1Controller.text.trim().isEmpty ||
        _orgStateController.text.trim().isEmpty ||
        _orgCityController.text.trim().isEmpty ||
        _orgOfficialEmailController.text.trim().isEmpty ||
        _orgIndustryTypeController.text.trim().isEmpty ||
        _orgPanNoController.text.trim().isEmpty ||
        _orgPhoneController.text.trim().isEmpty ||
        _orgWebsiteController.text.trim().isEmpty ||
        _orgHrPersonNameController.text.trim().isEmpty) {
      _showMessage('Please fill all required organisation details');
      return;
    }
    setState(() => _saving = true);
    final userRes = await _profileApi.updateUserProfile({
      'email': _orgOfficialEmailController.text.trim(),
      'phone': _orgPhoneController.text.trim(),
      if (_passwordController.text.trim().length >= 6) 'password': _passwordController.text.trim(),
    });
    final profileRes = await _profileApi.updateProfile({
      'company_name': _orgCompanyNameController.text.trim(),
      'gst_number': _gstNumberController.text.trim(),
      if (_hasTradeName) 'trade_name': _orgTradeNameController.text.trim(),
      'company_address': _orgAddress2Controller.text.trim().isEmpty
          ? _orgAddress1Controller.text.trim()
          : '${_orgAddress1Controller.text.trim()}, ${_orgAddress2Controller.text.trim()}',
      'state': _orgStateController.text.trim(),
      'city': _orgCityController.text.trim(),
      'authorized_signatory_email': _orgOfficialEmailController.text.trim(),
      'industry_type': _orgIndustryTypeController.text.trim(),
      'pan_no': _orgPanNoController.text.trim(),
      'organization_phone': _orgPhoneController.text.trim(),
      'company_website': _orgWebsiteController.text.trim(),
      'authorized_signatory_name': _orgHrPersonNameController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (userRes.isOk && profileRes.isOk) {
      _showMessage('Profile updated');
      Navigator.pop(context, true);
      return;
    }
    _showMessage(profileRes.error ?? userRes.error ?? 'Update failed');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    final state = _orgStateController.text;
    final cities = _stateCityMap[state] ?? const <String>[];
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: AppTextStyles.screenTitle(context).copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: GestureDetector(
                        onTap: _pickOrganizationLogo,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: AppColors.textFieldBackground,
                              backgroundImage:
                                  _profileImageUrl.isNotEmpty ? NetworkImage(_displayImageUrl) : null,
                              child: _profileImageUrl.isEmpty
                                  ? const Icon(Icons.business, size: 40, color: AppColors.textSecondary)
                                  : null,
                            ),
                            Container(
                              height: 28,
                              width: 28,
                              decoration: const BoxDecoration(color: AppColors.headerYellow, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 16, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(label: 'Company name', hint: 'Legal company name', controller: _orgCompanyNameController),
                    const SizedBox(height: AppSpacing.lg),
                    Text('GST number', style: AppTextStyles.bodyMedium(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(label: null, hint: 'GST number', controller: _gstNumberController),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _verifyGstLocally,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.headerYellow,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            child: Text(_gstVerified ? 'Verified' : 'Verify'),
                          ),
                        ),
                      ],
                    ),
                    if (_gstVerified) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Verified',
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasTradeName,
                          onChanged: (v) => setState(() => _hasTradeName = v ?? false),
                          activeColor: AppColors.headerYellow,
                        ),
                        Expanded(
                          child: Text('Do You have any Trade Name?', style: AppTextStyles.bodyMedium(context)),
                        ),
                      ],
                    ),
                    if (_hasTradeName) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(label: 'Trade name', hint: 'Enter trade name', controller: _orgTradeNameController),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    AppTextField(label: 'Address 1', hint: 'Office / Building / Street', controller: _orgAddress1Controller),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                        label: 'Address 2',
                        hint: 'Area / Landmark (optional)',
                        controller: _orgAddress2Controller),
                    const SizedBox(height: AppSpacing.lg),
                    _SearchableField(
                      label: 'Industry Type',
                      value: _orgIndustryTypeController.text,
                      hint: 'Select industry type',
                      options: const [
                        'Information Technology',
                        'Manufacturing',
                        'Banking & Finance',
                        'Healthcare',
                        'Education',
                        'Retail',
                        'Construction',
                        'Telecom',
                        'Logistics',
                        'Media & Entertainment',
                      ],
                      onSelected: (value) => setState(() => _orgIndustryTypeController.text = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(label: 'PAN No', hint: 'Enter PAN number', controller: _orgPanNoController),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Phone',
                      hint: 'Enter phone number',
                      controller: _orgPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Organization Website',
                      hint: 'https://example.com',
                      controller: _orgWebsiteController,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                        label: 'HR Person Name',
                        hint: 'Enter HR person name',
                        controller: _orgHrPersonNameController),
                    const SizedBox(height: AppSpacing.lg),
                    _SearchableField(
                      label: 'State',
                      value: _orgStateController.text,
                      hint: 'Select state',
                      options: _stateCityMap.keys.toList(),
                      onSelected: (value) {
                        setState(() {
                          _orgStateController.text = value;
                          _orgCityController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SearchableField(
                      label: 'City',
                      value: _orgCityController.text,
                      hint: 'Select city',
                      options: cities,
                      onSelected: (value) => setState(() => _orgCityController.text = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Official email', style: AppTextStyles.bodyMedium(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.textFieldBackground,
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      ),
                      child: Text(
                        _orgOfficialEmailController.text.isEmpty ? '-' : _orgOfficialEmailController.text,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Upload documents', style: AppTextStyles.headingMedium(context)),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDocumentTile('PAN', Icons.badge_outlined),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDocumentTile('AADHAR', Icons.perm_identity_outlined),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDocumentTile('CRO', Icons.description_outlined),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDocumentTile('Other Documents', Icons.folder_open_outlined),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                        label: 'Password (optional)',
                        hint: 'Min 6 characters',
                        controller: _passwordController,
                        obscureText: true),
                    const SizedBox(height: AppSpacing.xl),
                    AppPrimaryButton(
                      label: _saving ? 'Saving…' : 'Update Profile',
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDocumentTile(String key, IconData icon) {
    final selectedName = _orgDocumentNames[key];
    return InkWell(
      onTap: () => _pickDocument(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.textFieldBackground,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                selectedName == null ? '$key (tap to upload)' : '$key: $selectedName',
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            const Icon(Icons.upload_file, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SearchableField extends StatelessWidget {
  const _SearchableField({
    this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onSelected,
  });

  final String? label;
  final String value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
        ],
        InkWell(
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => _SearchBottomSheet(options: options, title: hint),
            );
            if (selected != null && selected.isNotEmpty) {
              onSelected(selected);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                      color: value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
      ],
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
        .where((item) => item.toLowerCase().contains(_searchController.text.trim().toLowerCase()))
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
  'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Tirupati', 'Nellore'],
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
  'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
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
