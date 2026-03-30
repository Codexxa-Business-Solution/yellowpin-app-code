import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/signup_args.dart';
import '../../core/api/api_config.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/profile_api.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../core/services/google_geocoding_service.dart';
import 'organization_map_picker_page.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final _authApi = AuthApi();
  final _profileApi = ProfileApi();
  final _imagePicker = ImagePicker();
  bool _loading = false;
  bool _jobSeekerEditReady = true;
  bool _jobSeekerEditLoadStarted = false;
  String _editProfileImageUrl = '';
  int _jobSeekerCurrentStep = 0;
  int _hrCurrentStep = 0;
  File? _profileImage;
  File? _organisationLogo;
  bool _hasTradeName = false;
  bool _organizationInitialized = false;
  bool _jobSeekerInitialized = false;
  bool _gstVerified = false;
  String _verifiedGstValue = '';
  int _organisationCurrentStep = 0;
  bool _organisationEditReady = true;
  bool _organisationEditLoadStarted = false;
  String _editOrganisationImageUrl = '';
  bool _obscureOrgPassword = true;
  bool _obscureOrgPasswordConfirm = true;
  /// direct | placement | contractor
  String _orgEntityType = 'direct';
  bool _legalNameChecked = false;

  final _titleController = TextEditingController(text: 'Ms');
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nameController = TextEditingController(); // Used for non-HR flows.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // HR
  final _companyNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _employmentTypeController = TextEditingController();
  final _industryTypeController = TextEditingController();
  final _totalExperienceController = TextEditingController();
  final _educationDetailsController = TextEditingController();
  final _skillsController = TextEditingController();
  final _genderController = TextEditingController();
  final _officialEmailController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  bool _hiringAuthorityConfirmed = false;
  // Organisation
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
  final Map<String, String> _orgDocumentNames = <String, String>{};
  final _orgDescriptionController = TextEditingController();
  final _orgLegalEntityNameController = TextEditingController();
  final _orgBusinessTypeController = TextEditingController();
  final _orgYearEstablishmentController = TextEditingController();
  final _orgEmployeeCountController = TextEditingController();
  final _orgPinCodeController = TextEditingController();
  final _orgContactDesignationController = TextEditingController();
  final _orgPasswordConfirmController = TextEditingController();
  // Institute
  final _instituteNameController = TextEditingController();
  int _instituteCurrentStep = 0;
  bool _instituteEditReady = true;
  bool _instituteEditLoadStarted = false;
  bool _instituteInitialized = false;
  String _editInstituteImageUrl = '';
  bool _obscureInstPassword = true;
  bool _obscureInstPasswordConfirm = true;
  File? _instituteLogo;
  final List<Map<String, String>> _instCourseRows = [];
  final _instAboutController = TextEditingController();
  final _instWebsiteController = TextEditingController();
  final _instTypeController = TextEditingController();
  final _instAffiliationController = TextEditingController();
  final _instAccreditationController = TextEditingController();
  final _instYearEstablishmentController = TextEditingController();
  final _instOfficialEmailController = TextEditingController();
  final _instPasswordConfirmController = TextEditingController();
  final _instCourseCategoryController = TextEditingController();
  final _instCourseSubcategoryController = TextEditingController();
  final _instAddress1Controller = TextEditingController();
  final _instAddress2Controller = TextEditingController();
  final _instStateController = TextEditingController();
  final _instCityController = TextEditingController();
  final _instPinCodeController = TextEditingController();
  final _instTpoNameController = TextEditingController();
  final _instContactDesignationController = TextEditingController();
  final _instContactEmailController = TextEditingController();
  final _instContactPhoneController = TextEditingController();
  // Job seeker specific
  final _jsSchoolController = TextEditingController();
  final _jsFieldOfStudyController = TextEditingController();
  final _jsDegreeController = TextEditingController();
  final _jsStartYearController = TextEditingController();
  final _jsEndYearController = TextEditingController();
  bool _jsCurrentlyPursuing = true;
  final _jsEmploymentTypeController = TextEditingController();
  final _jsCurrentJobTitleController = TextEditingController();
  final _jsCurrentCompanyController = TextEditingController();
  final _jsIndustryTypeController = TextEditingController();
  final _jsTotalExperienceController = TextEditingController();
  final _jsPhoneController = TextEditingController();

  SignUpArgs? get _signUpArgs {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is SignUpArgs ? args : null;
  }

  @override
  void initState() {
    super.initState();
    _gstNumberController.addListener(() {
      final current = _gstNumberController.text.trim();
      if (_verifiedGstValue.isNotEmpty &&
          current != _verifiedGstValue &&
          _gstVerified) {
        setState(() => _gstVerified = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = _signUpArgs;
    if (args?.isEditProfile == true && args?.role == 'job_seeker' && !_jobSeekerEditLoadStarted) {
      _jobSeekerEditLoadStarted = true;
      setState(() => _jobSeekerEditReady = false);
      _loadJobSeekerProfileForEdit();
    }
    final orgArgs = _signUpArgs;
    if (orgArgs?.isEditProfile == true &&
        orgArgs?.role == 'organisation' &&
        !_organisationEditLoadStarted) {
      _organisationEditLoadStarted = true;
      setState(() => _organisationEditReady = false);
      _loadOrganisationProfileForEdit();
    }
    final instArgs = _signUpArgs;
    if (instArgs?.isEditProfile == true &&
        instArgs?.role == 'institute' &&
        !_instituteEditLoadStarted) {
      _instituteEditLoadStarted = true;
      setState(() => _instituteEditReady = false);
      _loadInstituteProfileForEdit();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _jobTitleController.dispose();
    _employmentTypeController.dispose();
    _industryTypeController.dispose();
    _totalExperienceController.dispose();
    _educationDetailsController.dispose();
    _skillsController.dispose();
    _genderController.dispose();
    _officialEmailController.dispose();
    _stateController.dispose();
    _cityController.dispose();
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
    _orgDescriptionController.dispose();
    _orgLegalEntityNameController.dispose();
    _orgBusinessTypeController.dispose();
    _orgYearEstablishmentController.dispose();
    _orgEmployeeCountController.dispose();
    _orgPinCodeController.dispose();
    _orgContactDesignationController.dispose();
    _orgPasswordConfirmController.dispose();
    _instituteNameController.dispose();
    _instAboutController.dispose();
    _instWebsiteController.dispose();
    _instTypeController.dispose();
    _instAffiliationController.dispose();
    _instAccreditationController.dispose();
    _instYearEstablishmentController.dispose();
    _instOfficialEmailController.dispose();
    _instPasswordConfirmController.dispose();
    _instCourseCategoryController.dispose();
    _instCourseSubcategoryController.dispose();
    _instAddress1Controller.dispose();
    _instAddress2Controller.dispose();
    _instStateController.dispose();
    _instCityController.dispose();
    _instPinCodeController.dispose();
    _instTpoNameController.dispose();
    _instContactDesignationController.dispose();
    _instContactEmailController.dispose();
    _instContactPhoneController.dispose();
    _jsSchoolController.dispose();
    _jsFieldOfStudyController.dispose();
    _jsDegreeController.dispose();
    _jsStartYearController.dispose();
    _jsEndYearController.dispose();
    _jsEmploymentTypeController.dispose();
    _jsCurrentJobTitleController.dispose();
    _jsCurrentCompanyController.dispose();
    _jsIndustryTypeController.dispose();
    _jsTotalExperienceController.dispose();
    _jsPhoneController.dispose();
    super.dispose();
  }

  String _absoluteImageUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith(RegExp(r'^https?://'))) return p;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');
    return base + (p.startsWith('/') ? '' : '/') + p;
  }

  String? _extractYear(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final m = RegExp(r'(19|20)\d{2}').firstMatch(s);
    return m?.group(0);
  }

  void _applyNameFromApi(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final parts = trimmed.split(RegExp(r'\s+'));
    const titles = {'mr', 'mrs', 'ms', 'dr'};
    final first = parts.first.replaceAll('.', '').toLowerCase();
    if (parts.isNotEmpty && titles.contains(first)) {
      _titleController.text = parts.first;
      if (parts.length >= 2) _firstNameController.text = parts[1];
      if (parts.length >= 3) _lastNameController.text = parts.sublist(2).join(' ');
    } else {
      _firstNameController.text = parts.first;
      if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
    }
  }

  Future<void> _loadJobSeekerProfileForEdit() async {
    final res = await _profileApi.getProfile();
    if (!mounted) return;
    if (!res.isOk || res.data is! Map) {
      setState(() {
        _jobSeekerEditReady = true;
        _jobSeekerInitialized = true;
      });
      _showMessage('Could not load profile');
      return;
    }
    final data = res.data as Map;
    final user = data['data'];
    if (user is! Map) {
      setState(() {
        _jobSeekerEditReady = true;
        _jobSeekerInitialized = true;
      });
      return;
    }

    final imageUrl = (user['image'] ?? '').toString().trim();
    _editProfileImageUrl = imageUrl;

    _applyNameFromApi((user['name'] ?? '').toString());

    final phone = (user['phone'] ?? '').toString().trim();
    final email = (user['email'] ?? '').toString().trim();
    _emailController.text = email;
    if (phone.isNotEmpty) {
      _jsPhoneController.text = phone;
    }

    final gender = (user['gender'] ?? '').toString().trim().toLowerCase();
    if (gender.isNotEmpty) {
      _genderController.text = gender;
    }

    final extra = user['job_seeker_profile'] is Map
        ? Map<String, dynamic>.from(user['job_seeker_profile'] as Map)
        : <String, dynamic>{};

    _stateController.text = (extra['state'] ?? '').toString();
    _cityController.text = (extra['city'] ?? '').toString();

    _jsSchoolController.text = (extra['college_name'] ?? '').toString();
    _jsFieldOfStudyController.text = (extra['stream'] ?? '').toString();
    _jsDegreeController.text = (extra['qualification'] ?? extra['education'] ?? '').toString();

    final df = _extractYear(extra['duration_from']?.toString()) ?? (extra['duration_from'] ?? '').toString().trim();
    final dtRaw = (extra['duration_to'] ?? '').toString().trim();
    _jsStartYearController.text = df;
    final dtLower = dtRaw.toLowerCase();
    if (dtRaw.isEmpty || dtLower == 'present' || dtLower == 'ongoing') {
      _jsCurrentlyPursuing = true;
      _jsEndYearController.clear();
    } else {
      _jsCurrentlyPursuing = false;
      _jsEndYearController.text = _extractYear(dtRaw) ?? dtRaw;
    }

    _jsCurrentJobTitleController.text = (extra['job_title'] ?? '').toString();
    _jsCurrentCompanyController.text = (extra['company_name'] ?? '').toString();
    _jsEmploymentTypeController.text = (extra['employment_type'] ?? '').toString();
    _jsIndustryTypeController.text = (extra['industry_type'] ?? extra['industry'] ?? '').toString();

    var exp = (extra['experience_level'] ?? extra['years_of_experience'] ?? '').toString().trim();
    if (exp.isNotEmpty) {
      final digits = RegExp(r'\d+').firstMatch(exp);
      if (digits != null) {
        exp = digits.group(0)!;
        if (int.tryParse(exp) != null && int.parse(exp) > 10) {
          exp = '10+';
        }
      }
    }
    _jsTotalExperienceController.text = exp;

    if (!mounted) return;
    setState(() {
      _jobSeekerEditReady = true;
      _jobSeekerInitialized = true;
    });
  }

  Future<void> _loadOrganisationProfileForEdit() async {
    final res = await _profileApi.getProfile();
    if (!mounted) return;
    if (!res.isOk || res.data is! Map) {
      setState(() {
        _organisationEditReady = true;
        _organizationInitialized = true;
      });
      _showMessage('Could not load profile');
      return;
    }
    final data = (res.data as Map)['data'];
    if (data is! Map) {
      setState(() {
        _organisationEditReady = true;
        _organizationInitialized = true;
      });
      return;
    }

    _editOrganisationImageUrl = (data['image'] ?? '').toString().trim();
    _orgOfficialEmailController.text = (data['email'] ?? '').toString().trim();
    _orgPhoneController.text = (data['phone'] ?? '').toString().trim();

    final org = data['organisation_profile'] ?? data['organization_profile'];
    if (org is Map) {
      final o = Map<String, dynamic>.from(org);
      _orgCompanyNameController.text = (o['company_name'] ?? '').toString();
      _gstNumberController.text = (o['gst_number'] ?? '').toString();
      _orgTradeNameController.text = (o['trade_name'] ?? '').toString();
      _hasTradeName = _orgTradeNameController.text.trim().isNotEmpty;
      _orgDescriptionController.text = (o['company_description'] ?? o['description'] ?? '').toString();
      _orgWebsiteController.text = (o['company_website'] ?? '').toString();
      _orgIndustryTypeController.text = (o['industry_type'] ?? '').toString();
      _orgBusinessTypeController.text = (o['business_type'] ?? '').toString();
      _orgYearEstablishmentController.text = (o['year_of_establishment'] ?? '').toString();
      _orgEmployeeCountController.text = (o['number_of_employees'] ?? o['no_of_employment'] ?? '').toString();
      _orgPanNoController.text = (o['pan_no'] ?? '').toString();
      _orgHrPersonNameController.text =
          (o['authorized_signatory_name'] ?? o['hr_person_name'] ?? '').toString();
      _orgContactDesignationController.text = (o['designation'] ?? '').toString();

      final et = (o['entity_type'] ?? '').toString().toLowerCase();
      if (et.contains('placement')) {
        _orgEntityType = 'placement';
      } else if (et.contains('contract')) {
        _orgEntityType = 'contractor';
      } else {
        _orgEntityType = 'direct';
      }

      final companyAddress = (o['company_address'] ?? '').toString().trim();
      if (companyAddress.contains(',')) {
        final parts = companyAddress.split(',');
        _orgAddress1Controller.text = parts.first.trim();
        _orgAddress2Controller.text = parts.sublist(1).join(',').trim();
      } else {
        _orgAddress1Controller.text = companyAddress;
      }
      _orgStateController.text = (o['state'] ?? '').toString();
      _orgCityController.text = (o['city'] ?? '').toString();
      _orgPinCodeController.text = (o['pincode'] ?? o['pin_code'] ?? '').toString();

      final ln = (o['legal_name'] ?? '').toString().trim();
      if (ln.isNotEmpty) {
        _legalNameChecked = true;
        _orgLegalEntityNameController.text = ln;
      }
    }

    if (!mounted) return;
    setState(() {
      _organisationEditReady = true;
      _organizationInitialized = true;
    });
  }

  Future<void> _submitOrganisationProfileUpdate() async {
    if (!_validateOrganisationStep(0) ||
        !_validateOrganisationStep(1) ||
        !_validateOrganisationStep(2) ||
        !_validateOrganisationStep(3)) {
      return;
    }

    setState(() => _loading = true);

    if (_organisationLogo != null) {
      final up = await _profileApi.uploadProfileImage(_organisationLogo!);
      if (!mounted) return;
      if (up.isOk && up.data != null) {
        dynamic body = up.data;
        if (body is Map && body['data'] is Map) body = body['data'];
        final url = body is Map ? body['image']?.toString() : null;
        if (url != null && url.isNotEmpty) {
          _editOrganisationImageUrl = url;
          await AuthStorage.setProfileImageUrl(url);
        }
      }
    }

    final userBody = <String, dynamic>{
      'email': _orgOfficialEmailController.text.trim(),
      'phone': _orgPhoneController.text.trim(),
    };
    if (_passwordController.text.trim().length >= 6) {
      userBody['password'] = _passwordController.text.trim();
    }

    final entityLabel = switch (_orgEntityType) {
      'placement' => 'placement_consultancy',
      'contractor' => 'contractor',
      _ => 'direct_organization',
    };

    final profileBody = <String, dynamic>{
      'company_name': _orgCompanyNameController.text.trim(),
      'gst_number': _gstNumberController.text.trim(),
      if (_hasTradeName) 'trade_name': _orgTradeNameController.text.trim(),
      'company_address': _orgAddress2Controller.text.trim().isEmpty
          ? _orgAddress1Controller.text.trim()
          : '${_orgAddress1Controller.text.trim()}, ${_orgAddress2Controller.text.trim()}',
      'state': _orgStateController.text.trim(),
      'city': _orgCityController.text.trim(),
      'pincode': _orgPinCodeController.text.trim(),
      'authorized_signatory_email': _orgOfficialEmailController.text.trim(),
      'industry_type': _orgIndustryTypeController.text.trim(),
      'business_type': _orgBusinessTypeController.text.trim(),
      'year_of_establishment': _orgYearEstablishmentController.text.trim(),
      'number_of_employees': _orgEmployeeCountController.text.trim(),
      'pan_no': _orgPanNoController.text.trim(),
      'organization_phone': _orgPhoneController.text.trim(),
      'company_website': _orgWebsiteController.text.trim(),
      'authorized_signatory_name': _orgHrPersonNameController.text.trim(),
      'designation': _orgContactDesignationController.text.trim(),
      'company_description': _orgDescriptionController.text.trim(),
      'entity_type': entityLabel,
      if (_legalNameChecked) 'legal_name': _orgLegalEntityNameController.text.trim(),
    };

    final r1 = await _profileApi.updateUserProfile(userBody);
    final r2 = await _profileApi.updateProfile(profileBody);

    if (!mounted) return;
    setState(() => _loading = false);

    if (r1.isOk && r2.isOk) {
      await AuthStorage.setUserName(_orgCompanyNameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
      return;
    }
    _showMessage(r2.error ?? r1.error ?? 'Update failed');
  }

  Future<void> _loadInstituteProfileForEdit() async {
    final res = await _profileApi.getProfile();
    if (!mounted) return;
    if (!res.isOk || res.data is! Map) {
      setState(() {
        _instituteEditReady = true;
        _instituteInitialized = true;
      });
      _showMessage('Could not load profile');
      return;
    }
    final data = (res.data as Map)['data'];
    if (data is! Map) {
      setState(() {
        _instituteEditReady = true;
        _instituteInitialized = true;
      });
      return;
    }

    _editInstituteImageUrl = (data['image'] ?? '').toString().trim();
    _instOfficialEmailController.text = (data['email'] ?? '').toString().trim();
    _instContactEmailController.text = (data['email'] ?? '').toString().trim();
    _instContactPhoneController.text = (data['phone'] ?? '').toString().trim();

    _instituteNameController.text = (data['name'] ?? '').toString();
    _instAboutController.text = (data['bio'] ?? '').toString();

    final inst = data['institute_profile'];
    if (inst is Map) {
      final m = Map<String, dynamic>.from(inst);
      _instWebsiteController.text = (m['website'] ?? m['company_website'] ?? '').toString();
      _instTypeController.text = (m['institute_type'] ?? '').toString();
      _instAffiliationController.text = (m['affiliation_university'] ?? m['university_board'] ?? '').toString();
      _instAccreditationController.text = (m['accreditation'] ?? '').toString();
      _instYearEstablishmentController.text = (m['year_of_establishment'] ?? '').toString();
      _instAddress1Controller.text = (m['address_line1'] ?? '').toString();
      if (_instAddress1Controller.text.isEmpty) {
        final addr = (m['address'] ?? '').toString();
        if (addr.contains(',')) {
          final p = addr.split(',');
          _instAddress1Controller.text = p.first.trim();
          _instAddress2Controller.text = p.sublist(1).join(',').trim();
        } else {
          _instAddress1Controller.text = addr;
        }
      } else {
        _instAddress2Controller.text = (m['address_line2'] ?? '').toString();
      }
      _instStateController.text = (m['state'] ?? '').toString();
      _instCityController.text = (m['city'] ?? '').toString();
      _instPinCodeController.text = (m['pincode'] ?? m['pin_code'] ?? '').toString();
      _instTpoNameController.text = (m['tpo_name'] ?? '').toString();
      _instContactDesignationController.text = (m['designation'] ?? '').toString();
      final coursesJson = (m['courses_offered'] ?? '').toString();
      if (coursesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(coursesJson);
          if (decoded is List) {
            _instCourseRows.clear();
            for (final e in decoded) {
              if (e is Map) {
                _instCourseRows.add({
                  'category': (e['category'] ?? '').toString(),
                  'subcategory': (e['subcategory'] ?? '').toString(),
                });
              }
            }
          }
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _instituteEditReady = true;
      _instituteInitialized = true;
    });
  }

  Future<void> _submitInstituteProfileUpdate() async {
    if (!_validateInstituteStep(0) ||
        !_validateInstituteStep(1) ||
        !_validateInstituteStep(2) ||
        !_validateInstituteStep(3)) {
      return;
    }

    setState(() => _loading = true);

    if (_instituteLogo != null) {
      final up = await _profileApi.uploadProfileImage(_instituteLogo!);
      if (!mounted) return;
      if (up.isOk && up.data != null) {
        dynamic body = up.data;
        if (body is Map && body['data'] is Map) body = body['data'];
        final url = body is Map ? body['image']?.toString() : null;
        if (url != null && url.isNotEmpty) {
          _editInstituteImageUrl = url;
          await AuthStorage.setProfileImageUrl(url);
        }
      }
    }

    final userBody = <String, dynamic>{
      'name': _instituteNameController.text.trim(),
      'bio': _instAboutController.text.trim(),
      'email': _instOfficialEmailController.text.trim(),
      'phone': _instContactPhoneController.text.trim(),
    };
    if (_passwordController.text.trim().length >= 6) {
      userBody['password'] = _passwordController.text.trim();
    }

    final institutePayload = <String, dynamic>{
      'institute_name': _instituteNameController.text.trim(),
      'website': _instWebsiteController.text.trim(),
      'about_us': _instAboutController.text.trim(),
      'institute_type': _instTypeController.text.trim(),
      'affiliation_university': _instAffiliationController.text.trim(),
      'accreditation': _instAccreditationController.text.trim(),
      'year_of_establishment': _instYearEstablishmentController.text.trim(),
      'address': _instAddress2Controller.text.trim().isEmpty
          ? _instAddress1Controller.text.trim()
          : '${_instAddress1Controller.text.trim()}, ${_instAddress2Controller.text.trim()}',
      'state': _instStateController.text.trim(),
      'city': _instCityController.text.trim(),
      'pincode': _instPinCodeController.text.trim(),
      'tpo_name': _instTpoNameController.text.trim(),
      'designation': _instContactDesignationController.text.trim(),
      'tpo_email': _instContactEmailController.text.trim(),
      'course_category': _instCourseCategoryController.text.trim(),
      'course_subcategory': _instCourseSubcategoryController.text.trim(),
      'courses_offered': jsonEncode(_instCourseRows),
    };

    final r1 = await _profileApi.updateUserProfile(userBody);
    final r2 = await _profileApi.updateProfile(<String, dynamic>{
      'institute_profile': institutePayload,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (r1.isOk && r2.isOk) {
      await AuthStorage.setUserName(_instituteNameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
      return;
    }
    _showMessage(r2.error ?? r1.error ?? 'Update failed');
  }

  bool _validateInstituteStep(int step) {
    final edit = _signUpArgs?.isEditProfile == true;
    if (step == 0) {
      if (_instituteNameController.text.trim().isEmpty) {
        _showMessage('Please enter institute name');
        return false;
      }
      if (_instOfficialEmailController.text.trim().isEmpty ||
          !_instOfficialEmailController.text.trim().contains('@')) {
        _showMessage('Please enter a valid email');
        return false;
      }
      if (!edit) {
        if (_passwordController.text.trim().isEmpty || _instPasswordConfirmController.text.trim().isEmpty) {
          _showMessage('Please enter password and confirmation');
          return false;
        }
        if (_passwordController.text.trim() != _instPasswordConfirmController.text.trim()) {
          _showMessage('Passwords do not match');
          return false;
        }
        if (_passwordController.text.trim().length < 6) {
          _showMessage('Password must be at least 6 characters');
          return false;
        }
      }
      return true;
    }
    if (step == 1) {
      if (_instCourseRows.isEmpty) {
        _showMessage('Add at least one course (enter category & subcategory, tap +)');
        return false;
      }
      return true;
    }
    if (step == 2) {
      if (_instAddress1Controller.text.trim().isEmpty ||
          _instStateController.text.trim().isEmpty ||
          _instCityController.text.trim().isEmpty ||
          _instPinCodeController.text.trim().isEmpty) {
        _showMessage('Please complete location details');
        return false;
      }
      return true;
    }
    if (step == 3) {
      if (_instTpoNameController.text.trim().isEmpty ||
          _instContactDesignationController.text.trim().isEmpty ||
          _instContactEmailController.text.trim().isEmpty ||
          _instContactPhoneController.text.trim().isEmpty) {
        _showMessage('Please fill contact person details');
        return false;
      }
      return true;
    }
    return true;
  }

  Future<void> _submitInstituteSignUp(SignUpArgs args) async {
    if (!_validateInstituteStep(0) ||
        !_validateInstituteStep(1) ||
        !_validateInstituteStep(2) ||
        !_validateInstituteStep(3)) {
      return;
    }

    final address = _instAddress2Controller.text.trim().isEmpty
        ? _instAddress1Controller.text.trim()
        : '${_instAddress1Controller.text.trim()}, ${_instAddress2Controller.text.trim()}';

    final streams = _instCourseRows
        .map((e) => '${e['category']?.trim() ?? ''} — ${e['subcategory']?.trim() ?? ''}'.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _loading = true);
    final res = await _authApi.signUpWithPhone(
      phone: args.phone,
      name: _instituteNameController.text.trim(),
      email: _instOfficialEmailController.text.trim(),
      password: _passwordController.text,
      role: 'institute',
      instituteName: _instituteNameController.text.trim(),
      affiliationUniversity: _instAffiliationController.text.trim().isEmpty
          ? null
          : _instAffiliationController.text.trim(),
      tpoName: _instTpoNameController.text.trim().isEmpty ? null : _instTpoNameController.text.trim(),
      tpoEmail: _instContactEmailController.text.trim().isEmpty ? null : _instContactEmailController.text.trim(),
      officialEmail: _instOfficialEmailController.text.trim().isEmpty ? null : _instOfficialEmailController.text.trim(),
      address: address.isEmpty ? null : address,
      city: _instCityController.text.trim().isEmpty ? null : _instCityController.text.trim(),
      state: _instStateController.text.trim().isEmpty ? null : _instStateController.text.trim(),
      streamsOffered: streams.isEmpty ? null : streams,
      organizationPhone: _instContactPhoneController.text.trim().isEmpty
          ? null
          : _instContactPhoneController.text.trim(),
      profileImagePath: _instituteLogo?.path,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.isOk) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    } else {
      String msg = res.error ?? 'Sign up failed';
      if (res.data is Map && res.data['message'] != null) {
        msg = res.data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 5)),
      );
    }
  }

  void _onInstitutePrimary(SignUpArgs? args) {
    final edit = args?.isEditProfile == true;
    if (args == null || args.role != 'institute') return;
    if (_instituteCurrentStep < 3) {
      if (!_validateInstituteStep(_instituteCurrentStep)) return;
      if (_instituteCurrentStep == 2 && _instContactEmailController.text.trim().isEmpty) {
        _instContactEmailController.text = _instOfficialEmailController.text.trim();
      }
      setState(() => _instituteCurrentStep += 1);
      return;
    }
    if (edit) {
      _submitInstituteProfileUpdate();
    } else {
      _submitInstituteSignUp(args);
    }
  }

  void _addInstituteCourseFromFields() {
    final cat = _instCourseCategoryController.text.trim();
    final sub = _instCourseSubcategoryController.text.trim();
    if (cat.isEmpty || sub.isEmpty) {
      _showMessage('Enter course category and subcategory');
      return;
    }
    setState(() {
      _instCourseRows.add({'category': cat, 'subcategory': sub});
      _instCourseCategoryController.clear();
      _instCourseSubcategoryController.clear();
    });
  }

  String _instituteAppBarTitle() {
    switch (_instituteCurrentStep) {
      case 0:
        return 'Institute Profile';
      case 1:
        return 'Course Details';
      case 2:
        return 'Location Details';
      case 3:
        return 'Contact Person Details';
      default:
        return 'Institute';
    }
  }

  Future<void> _openInstituteMapPicker() async {
    final r = await Navigator.push<OrganizationLocationMapResult>(
      context,
      MaterialPageRoute(builder: (_) => const OrganizationMapPickerPage()),
    );
    if (r == null || !mounted) return;
    setState(() {
      _instAddress1Controller.text = r.formattedAddress;
      if (r.city.isNotEmpty) _instCityController.text = r.city;
      if (r.state.isNotEmpty) _instStateController.text = r.state;
      if (r.pinCode.isNotEmpty) _instPinCodeController.text = r.pinCode;
    });
  }

  Future<void> _useInstituteCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Please turn on location services');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is required');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    final geo = GoogleGeocodingService();
    final r = await geo.reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted || r == null) {
      if (mounted) _showMessage('Could not resolve address');
      return;
    }
    setState(() {
      _instAddress1Controller.text = r.formattedAddress;
      if (r.city.isNotEmpty) _instCityController.text = r.city;
      if (r.state.isNotEmpty) _instStateController.text = r.state;
      if (r.pinCode.isNotEmpty) _instPinCodeController.text = r.pinCode;
    });
  }

  Future<void> _pickInstituteLogo() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _instituteLogo = File(picked.path));
  }

  List<Widget> _buildInstituteStepContent(SignUpArgs? args) {
    final edit = args?.isEditProfile == true;
    final state = _instStateController.text;
    final cities = _stateCityMap[state] ?? const <String>[];
    final logoUrl = _absoluteImageUrl(_editInstituteImageUrl);

    switch (_instituteCurrentStep) {
      case 0:
        return [
          Center(
            child: GestureDetector(
              onTap: _pickInstituteLogo,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.textFieldBackground,
                    backgroundImage: _instituteLogo != null
                        ? FileImage(_instituteLogo!)
                        : (logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null),
                    child: _instituteLogo == null && logoUrl.isEmpty
                        ? const Icon(Icons.school_outlined, size: 44, color: AppColors.textSecondary)
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
          AppTextField(label: 'Institute Name', hint: 'Name of institute', controller: _instituteNameController),
          const SizedBox(height: AppSpacing.lg),
          Text('About Us', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _instAboutController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell students about your institute',
              filled: true,
              fillColor: AppColors.textFieldBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Website Url',
            hint: 'https://',
            controller: _instWebsiteController,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Institute Type', hint: 'e.g. University, College', controller: _instTypeController),
          const SizedBox(height: AppSpacing.lg),
          _SearchableField(
            label: 'Affiliation/ University Name',
            value: _instAffiliationController.text,
            hint: 'Select or pick',
            options: const [
              'University of Mumbai',
              'Savitribai Phule Pune University',
              'Shivaji University',
              'Dr. Babasaheb Ambedkar Technological University',
              'Other',
            ],
            onSelected: (value) => setState(() => _instAffiliationController.text = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SearchableField(
            label: 'Approval/Accreditation',
            value: _instAccreditationController.text,
            hint: 'Select',
            options: const ['NAAC A++', 'NAAC A+', 'NAAC A', 'NBA', 'AICTE', 'UGC', 'Other'],
            onSelected: (value) => setState(() => _instAccreditationController.text = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Year Of Establishment',
            hint: 'e.g. 1998',
            controller: _instYearEstablishmentController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Email',
            hint: 'sayalirane@gmail.com',
            controller: _instOfficialEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
          if (!edit) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Password',
              hint: 'Yellowpin@123',
              controller: _passwordController,
              obscureText: _obscureInstPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscureInstPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureInstPassword = !_obscureInstPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: _instPasswordConfirmController,
              obscureText: _obscureInstPasswordConfirm,
              suffixIcon: IconButton(
                icon: Icon(_obscureInstPasswordConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureInstPasswordConfirm = !_obscureInstPasswordConfirm),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ];
      case 1:
        return [
          Text(
            "Let's Set Up Your Course Details",
            style: AppTextStyles.headingLarge(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add key information to attract the right students.',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            label: 'Course Category',
            hint: 'e.g. Engineering',
            controller: _instCourseCategoryController,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SearchableField(
            label: 'Course Subcategory',
            value: _instCourseSubcategoryController.text,
            hint: 'Select subcategory',
            options: const [
              'Computer Science',
              'Mechanical',
              'Electronics',
              'Civil',
              'Business Administration',
              'Design',
              'Other',
            ],
            allowCustomEntry: true,
            customSubmitLabel: 'Use this value',
            onSelected: (value) => setState(() => _instCourseSubcategoryController.text = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Material(
                color: AppColors.headerYellow,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _addInstituteCourseFromFields,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.add, color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Add Courses', style: AppTextStyles.bodyMedium(context)),
            ],
          ),
          if (_instCourseRows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Added courses', style: AppTextStyles.bodyMedium(context)),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(_instCourseRows.length, (i) {
              final row = _instCourseRows[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${row['category']} — ${row['subcategory']}',
                        style: AppTextStyles.bodySmall(context),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() {
                        if (i < _instCourseRows.length) _instCourseRows.removeAt(i);
                      }),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: AppSpacing.xl),
        ];
      case 2:
        return [
          Text(
            "Let's Set Your Location",
            style: AppTextStyles.headingLarge(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your location to get relevant opportunities.',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: _useInstituteCurrentLocation,
            child: Row(
              children: [
                Text('Use my current location', style: AppTextStyles.link(context)),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.north_east, size: 18, color: AppColors.textPrimary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _openInstituteMapPicker,
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Pick on map'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(label: 'Address 1', hint: 'Street / building', controller: _instAddress1Controller),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Address 2', hint: 'Area (optional)', controller: _instAddress2Controller),
          const SizedBox(height: AppSpacing.lg),
          _SearchableField(
            label: 'State',
            value: _instStateController.text,
            hint: 'Select state',
            options: _stateCityMap.keys.toList(),
            onSelected: (value) {
              setState(() {
                _instStateController.text = value;
                _instCityController.clear();
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SearchableField(
            label: 'City',
            value: _instCityController.text,
            hint: 'Select city',
            options: cities,
            onSelected: (value) => setState(() => _instCityController.text = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'PinCode',
            hint: 'Postal code',
            controller: _instPinCodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.xl),
        ];
      case 3:
        return [
          Text(
            "Let's Build Your Professional Story",
            style: AppTextStyles.headingLarge(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fill in your details to create a strong profile.',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(label: 'TPO Name', hint: 'Name', controller: _instTpoNameController),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Designation', hint: 'Role', controller: _instContactDesignationController),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Email',
            hint: 'you@institute.edu',
            controller: _instContactEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Phone',
            hint: 'Phone number',
            controller: _instContactPhoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.xl),
        ];
      default:
        return [];
    }
  }

  bool _validateOrganisationStep(int step) {
    final edit = _signUpArgs?.isEditProfile == true;
    if (step == 0) {
      if (_orgCompanyNameController.text.trim().isEmpty) {
        _showMessage('Please enter company name');
        return false;
      }
      if (_orgOfficialEmailController.text.trim().isEmpty ||
          !_orgOfficialEmailController.text.trim().contains('@')) {
        _showMessage('Please enter a valid email');
        return false;
      }
      if (!edit) {
        if (_passwordController.text.trim().isEmpty ||
            _orgPasswordConfirmController.text.trim().isEmpty) {
          _showMessage('Please enter password and confirmation');
          return false;
        }
        if (_passwordController.text.trim() != _orgPasswordConfirmController.text.trim()) {
          _showMessage('Passwords do not match');
          return false;
        }
        if (_passwordController.text.trim().length < 6) {
          _showMessage('Password must be at least 6 characters');
          return false;
        }
      }
      if (_legalNameChecked && _orgLegalEntityNameController.text.trim().isEmpty) {
        _showMessage('Please enter legal name');
        return false;
      }
      return true;
    }
    if (step == 1) {
      if (_orgIndustryTypeController.text.trim().isEmpty ||
          _orgBusinessTypeController.text.trim().isEmpty ||
          _orgYearEstablishmentController.text.trim().isEmpty ||
          _orgEmployeeCountController.text.trim().isEmpty ||
          _gstNumberController.text.trim().isEmpty ||
          _orgPanNoController.text.trim().isEmpty) {
        _showMessage('Please fill all required organization details');
        return false;
      }
      if (!_gstVerified) {
        _showMessage('Please verify GST number');
        return false;
      }
      return true;
    }
    if (step == 2) {
      if (_orgAddress1Controller.text.trim().isEmpty ||
          _orgStateController.text.trim().isEmpty ||
          _orgCityController.text.trim().isEmpty ||
          _orgPinCodeController.text.trim().isEmpty) {
        _showMessage('Please complete location details');
        return false;
      }
      return true;
    }
    if (step == 3) {
      if (_orgHrPersonNameController.text.trim().isEmpty ||
          _orgContactDesignationController.text.trim().isEmpty ||
          _orgOfficialEmailController.text.trim().isEmpty ||
          _orgPhoneController.text.trim().isEmpty) {
        _showMessage('Please fill contact person details');
        return false;
      }
      return true;
    }
    return true;
  }

  Future<void> _submitOrganisationSignUp(SignUpArgs args) async {
    if (!_validateOrganisationStep(0) ||
        !_validateOrganisationStep(1) ||
        !_validateOrganisationStep(2) ||
        !_validateOrganisationStep(3)) {
      return;
    }

    setState(() => _loading = true);
    final role = args.role!;
    final name = _orgCompanyNameController.text.trim();
    final email = _orgOfficialEmailController.text.trim();
    final password = _passwordController.text;
    final res = await _authApi.signUpWithPhone(
      phone: args.phone,
      name: name,
      email: email,
      password: password,
      role: role,
      companyName: _orgCompanyNameController.text.trim(),
      gstNumber: _gstNumberController.text.trim(),
      industryType: _orgIndustryTypeController.text.trim().isEmpty
          ? null
          : _orgIndustryTypeController.text.trim(),
      panNo: _orgPanNoController.text.trim().isEmpty ? null : _orgPanNoController.text.trim(),
      organizationPhone: _orgPhoneController.text.trim().isEmpty ? null : _orgPhoneController.text.trim(),
      companyWebsite: _orgWebsiteController.text.trim().isEmpty ? null : _orgWebsiteController.text.trim(),
      hrPersonName: _orgHrPersonNameController.text.trim().isEmpty ? null : _orgHrPersonNameController.text.trim(),
      tradeName: _hasTradeName && _orgTradeNameController.text.trim().isNotEmpty
          ? _orgTradeNameController.text.trim()
          : null,
      companyAddress: _orgAddress2Controller.text.trim().isEmpty
          ? _orgAddress1Controller.text.trim()
          : '${_orgAddress1Controller.text.trim()}, ${_orgAddress2Controller.text.trim()}',
      state: _orgStateController.text.trim().isEmpty ? null : _orgStateController.text.trim(),
      city: _orgCityController.text.trim().isEmpty ? null : _orgCityController.text.trim(),
      authorizedSignatoryEmail: _orgOfficialEmailController.text.trim().isEmpty
          ? null
          : _orgOfficialEmailController.text.trim(),
      profileImagePath: _organisationLogo?.path,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.isOk) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    } else {
      String msg = res.error ?? 'Sign up failed';
      if (res.data is Map && res.data['errors'] is Map) {
        final errors = res.data['errors'] as Map;
        final parts = <String>[];
        for (final entry in errors.entries) {
          final list = entry.value;
          final text = list is List && list.isNotEmpty ? list.first.toString() : list.toString();
          parts.add('${entry.key}: $text');
        }
        if (parts.isNotEmpty) msg = parts.join('\n');
      } else if (res.data is Map && res.data['message'] != null) {
        msg = res.data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 5)),
      );
    }
  }

  void _onOrganisationPrimary(SignUpArgs? args) {
    final edit = args?.isEditProfile == true;
    if (args == null || args.role != 'organisation') return;
    if (_organisationCurrentStep < 3) {
      if (!_validateOrganisationStep(_organisationCurrentStep)) return;
      setState(() => _organisationCurrentStep += 1);
      return;
    }
    if (edit) {
      _submitOrganisationProfileUpdate();
    } else {
      _submitOrganisationSignUp(args);
    }
  }

  Future<void> _onNext() async {
    final args = _signUpArgs;
    if (args == null || args.phone.isEmpty || args.role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing sign-up data'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final role = args.role!;
    final name = role == 'hr'
        ? _hrDisplayName
        : _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill name, email and password'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (role == 'hr' && !_validateHrBeforeSubmit()) {
      return;
    }

    setState(() => _loading = true);
    final res = await _authApi.signUpWithPhone(
      phone: args.phone,
      name: role == 'hr' ? _hrDisplayName : name,
      email: email,
      password: password,
      role: role,
      companyName: role == 'hr'
          ? (_companyNameController.text.trim().isEmpty
                ? null
                : _companyNameController.text.trim())
          : (role == 'organisation'
                ? _orgCompanyNameController.text.trim()
                : null),
      jobTitle: _jobTitleController.text.trim().isEmpty
          ? null
          : _jobTitleController.text.trim(),
      employmentType: _employmentTypeController.text.trim().isEmpty
          ? null
          : _employmentTypeController.text.trim(),
      totalExperience: int.tryParse(_totalExperienceController.text.trim()),
      gender: _genderController.text.trim().isEmpty
          ? null
          : _genderController.text.trim(),
      officialEmail: _officialEmailController.text.trim().isEmpty
          ? null
          : _officialEmailController.text.trim(),
      hiringAuthorityConfirmed: role == 'hr' ? _hiringAuthorityConfirmed : null,
      educationDetails: role == 'hr'
          ? (_educationDetailsController.text.trim().isEmpty
                ? null
                : _educationDetailsController.text.trim())
          : null,
      hrSkills: role == 'hr' ? _parsedSkills : null,
      hrState: role == 'hr'
          ? (_stateController.text.trim().isEmpty
                ? null
                : _stateController.text.trim())
          : null,
      hrCity: role == 'hr'
          ? (_cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim())
          : null,
      gstNumber: role == 'organisation'
          ? _gstNumberController.text.trim()
          : null,
      industryType: role == 'organisation'
          ? (_orgIndustryTypeController.text.trim().isEmpty
                ? null
                : _orgIndustryTypeController.text.trim())
          : _industryTypeController.text.trim().isEmpty
          ? null
          : _industryTypeController.text.trim(),
      panNo: role == 'organisation'
          ? (_orgPanNoController.text.trim().isEmpty
                ? null
                : _orgPanNoController.text.trim())
          : null,
      organizationPhone: role == 'organisation'
          ? (_orgPhoneController.text.trim().isEmpty
                ? null
                : _orgPhoneController.text.trim())
          : null,
      companyWebsite: role == 'organisation'
          ? (_orgWebsiteController.text.trim().isEmpty
                ? null
                : _orgWebsiteController.text.trim())
          : null,
      hrPersonName: role == 'organisation'
          ? (_orgHrPersonNameController.text.trim().isEmpty
                ? null
                : _orgHrPersonNameController.text.trim())
          : null,
      tradeName: role == 'organisation' && _hasTradeName
          ? (_orgTradeNameController.text.trim().isEmpty
                ? null
                : _orgTradeNameController.text.trim())
          : null,
      companyAddress: role == 'organisation'
          ? (_orgAddress2Controller.text.trim().isEmpty
                ? _orgAddress1Controller.text.trim()
                : '${_orgAddress1Controller.text.trim()}, ${_orgAddress2Controller.text.trim()}')
          : null,
      state: role == 'organisation'
          ? (_orgStateController.text.trim().isEmpty
                ? null
                : _orgStateController.text.trim())
          : null,
      city: role == 'organisation'
          ? (_orgCityController.text.trim().isEmpty
                ? null
                : _orgCityController.text.trim())
          : null,
      authorizedSignatoryEmail: role == 'organisation'
          ? (_orgOfficialEmailController.text.trim().isEmpty
                ? null
                : _orgOfficialEmailController.text.trim())
          : null,
      instituteName: role == 'institute'
          ? _instituteNameController.text.trim()
          : null,
      profileImagePath: role == 'hr'
          ? _profileImage?.path
          : role == 'organisation'
          ? _organisationLogo?.path
          : null,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.isOk) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    } else {
      String msg = res.error ?? 'Sign up failed';
      if (res.data is Map && res.data['errors'] is Map) {
        final errors = res.data['errors'] as Map;
        final parts = <String>[];
        for (final entry in errors.entries) {
          final list = entry.value;
          final text = list is List && list.isNotEmpty
              ? list.first.toString()
              : list.toString();
          parts.add('${entry.key}: $text');
        }
        if (parts.isNotEmpty) msg = parts.join('\n');
      } else if (res.data is Map && res.data['message'] != null) {
        msg = res.data['message'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
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
    final args = _signUpArgs;
    final role = args?.role ?? 'hr';
    final isHr = role == 'hr';
    final isJobSeeker = role == 'job_seeker';
    final isOrganisation = role == 'organisation';
    final isInstitute = role == 'institute';
    final isJobSeekerEdit = isJobSeeker && args?.isEditProfile == true;
    final isOrganisationEdit = isOrganisation && args?.isEditProfile == true;
    final isInstituteEdit = isInstitute && args?.isEditProfile == true;
    if (isInstitute && !_instituteInitialized && args?.isEditProfile != true) {
      _instituteInitialized = true;
      if (args?.phone.contains('@') == true) {
        _instOfficialEmailController.text = args!.phone.trim();
      }
    }
    if (isOrganisation && !_organizationInitialized && args?.isEditProfile != true) {
      _organizationInitialized = true;
      if (args?.phone.contains('@') == true) {
        _orgOfficialEmailController.text = args!.phone.trim();
      }
    }
    if (isJobSeeker && !_jobSeekerInitialized && args?.isEditProfile != true) {
      _jobSeekerInitialized = true;
      final identifier = args?.phone.trim() ?? '';
      if (identifier.contains('@')) {
        _emailController.text = identifier;
      } else if (identifier.isNotEmpty) {
        _jsPhoneController.text = identifier;
      }
    }

    if (isJobSeekerEdit && !_jobSeekerEditReady) {
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
            'Edit profile',
            style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (isOrganisationEdit && !_organisationEditReady) {
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
            'Edit profile',
            style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (isInstituteEdit && !_instituteEditReady) {
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
            'Edit profile',
            style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.headerYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (isOrganisation && _organisationCurrentStep > 0) {
              setState(() => _organisationCurrentStep -= 1);
              return;
            }
            if (isInstitute && _instituteCurrentStep > 0) {
              setState(() => _instituteCurrentStep -= 1);
              return;
            }
            if (isJobSeeker && _jobSeekerCurrentStep > 0) {
              setState(() => _jobSeekerCurrentStep -= 1);
              return;
            }
            if (isHr && _hrCurrentStep > 0) {
              setState(() => _hrCurrentStep -= 1);
              return;
            }
            Navigator.pop(context);
          },
        ),
        title: Text(
          isJobSeeker
              ? (_jobSeekerCurrentStep == 0
                    ? 'Personal Profile'
                    : _jobSeekerCurrentStep == 1
                    ? 'Location Details'
                    : _jobSeekerCurrentStep == 2
                    ? 'Education Details'
                    : 'Professional Details')
              : (isOrganisation
                    ? _organisationAppBarTitle()
                    : (isInstitute ? _instituteAppBarTitle() : '')),
          style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isHr || _hrCurrentStep < 2) ...[
                // Text(
                //   'Your profile helps you discover new people and opportunities',
                //   style: AppTextStyles.headingMedium(context).copyWith(fontSize: 18),
                // ),
                if (!isJobSeeker) const SizedBox(height: AppSpacing.xxl),
              ],
              if (isJobSeeker)
                ..._buildJobSeekerStepContent(args)
              else if (isHr)
                ..._buildHrStepContent(args)
              else if (!isOrganisation && !isInstitute) ...[
                AppTextField(
                  label: 'Full name',
                  hint: 'Your name',
                  controller: _nameController,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Password',
                  hint: 'Min 6 characters',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
              if (isOrganisation) ..._buildOrganisationStepContent(args),
              if (isInstitute) ..._buildInstituteStepContent(args),
              AppPrimaryButton(
                label: _loading
                    ? (isJobSeekerEdit
                          ? 'Updating profile…'
                          : isOrganisationEdit || isInstituteEdit
                              ? 'Saving…'
                              : 'Creating account…')
                    : (isJobSeeker
                          ? (_jobSeekerCurrentStep == 3
                                ? (isJobSeekerEdit ? 'Update Profile' : 'Register')
                                : 'Next')
                          : (isOrganisation
                                ? (_organisationCurrentStep == 3
                                      ? (isOrganisationEdit ? 'Update Profile' : 'Register')
                                      : 'Next')
                                : (isInstitute
                                      ? (_instituteCurrentStep == 3
                                            ? (isInstituteEdit ? 'Update Profile' : 'Register')
                                            : 'Next')
                                      : (isHr
                                            ? (_hrCurrentStep == 2 ? 'Register' : 'Next')
                                            : 'Next')))),
                onPressed: _loading
                    ? null
                    : (isJobSeeker
                          ? () {
                              if (_jobSeekerCurrentStep < 3) {
                                if (!_validateJobSeekerStep(_jobSeekerCurrentStep)) return;
                                setState(() => _jobSeekerCurrentStep += 1);
                              } else {
                                if (isJobSeekerEdit) {
                                  _submitJobSeekerProfileUpdate();
                                } else {
                                  _submitJobSeekerRegistration(args);
                                }
                              }
                            }
                          : (isOrganisation
                                ? () => _onOrganisationPrimary(args)
                                : (isInstitute
                                      ? () => _onInstitutePrimary(args)
                                      : (isHr
                                          ? () {
                                              if (_hrCurrentStep < 2) {
                                                _goToNextHrStep();
                                              } else {
                                                _onNext();
                                              }
                                            }
                                          : _onNext)))),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildJobSeekerStepContent(SignUpArgs? args) {
    final identifier = (args?.phone ?? '').trim();
    final isEdit = args?.isEditProfile == true;
    final isEmailIdentifier = identifier.contains('@');
    final avatarUrl = _absoluteImageUrl(_editProfileImageUrl);
    if (_jobSeekerCurrentStep == 0) {
      return [
        Center(
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.textFieldBackground,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null),
                  child: _profileImage == null && avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 44, color: AppColors.textSecondary)
                      : null,
                ),
                Container(
                  height: 26,
                  width: 26,
                  decoration: const BoxDecoration(color: AppColors.headerYellow, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 14, color: AppColors.textPrimary),
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
                label: null,
                value: _titleController.text,
                hint: 'MS',
                options: const ['Mr', 'Mrs', 'Ms'],
                onSelected: (v) => setState(() => _titleController.text = v),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: AppTextField(label: 'First Name', hint: 'Sayali', controller: _firstNameController),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Last Name', hint: 'Rane', controller: _lastNameController),
        const SizedBox(height: AppSpacing.lg),
        Text('Gender', style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: ['Male', 'Female', 'Other']
              .map(
                (gender) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _genderController.text = gender.toLowerCase()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _genderController.text == gender.toLowerCase() ? AppColors.white : AppColors.textFieldBackground,
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                          border: Border.all(
                            color: _genderController.text == gender.toLowerCase() ? AppColors.headerYellow : AppColors.inputBorder,
                          ),
                        ),
                        child: Text(gender, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium(context)),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isEdit)
          AppTextField(
            label: 'Phone',
            hint: '9112345678',
            controller: _jsPhoneController,
            keyboardType: TextInputType.phone,
          )
        else if (isEmailIdentifier)
          AppTextField(
            label: 'Phone',
            hint: '9112345678',
            controller: _jsPhoneController,
            keyboardType: TextInputType.phone,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone', style: AppTextStyles.bodyMedium(context)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.textFieldBackground,
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: Text(identifier, style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Email', hint: 'sayalirane@gmail.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
        if (!isEdit) ...[
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Password', hint: 'Yellowpin@123', controller: _passwordController, obscureText: true),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Confirm Password', hint: '********', controller: _officialEmailController, obscureText: true),
        ],
        const SizedBox(height: AppSpacing.xl),
      ];
    }

    if (_jobSeekerCurrentStep == 1) {
      final selectedState = _stateController.text.trim();
      final cities = _stateCityMap[selectedState] ?? const <String>[];
      return [
        Text("Let’s Set Your Location", style: AppTextStyles.headingLarge(context).copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Add your location to get relevant opportunities.',
          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SearchableField(
          label: 'State',
          value: _stateController.text,
          hint: 'Select State',
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
          label: 'City',
          value: _cityController.text,
          hint: 'Select City',
          options: cities,
          onSelected: (value) => setState(() => _cityController.text = value),
        ),
        const SizedBox(height: AppSpacing.xl),
      ];
    }

    if (_jobSeekerCurrentStep == 2) {
      final degreeOptions = _degreeByField[_jsFieldOfStudyController.text] ?? const ['Bachelors', 'Masters'];
      return [
        Text("Let’s Capture Your Education Story", style: AppTextStyles.headingLarge(context).copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Highlight your education.',
          style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SearchableField(
          label: 'School/ Colleges Name',
          value: _jsSchoolController.text,
          hint: 'Select or type school/college',
          options: _schoolCollegeOptions,
          allowCustomEntry: true,
          customSubmitLabel: 'Use typed value',
          onSelected: (value) => setState(() => _jsSchoolController.text = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SearchableField(
          label: 'Field Of Study',
          value: _jsFieldOfStudyController.text,
          hint: 'Select field of study',
          options: _fieldOfStudyOptions,
          onSelected: (value) {
            setState(() {
              _jsFieldOfStudyController.text = value;
              _jsDegreeController.clear();
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _SearchableField(
          label: 'Degree',
          value: _jsDegreeController.text,
          hint: 'Select degree',
          options: degreeOptions,
          onSelected: (value) => setState(() => _jsDegreeController.text = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _SearchableField(
                label: 'Start Year',
                value: _jsStartYearController.text,
                hint: 'Start Year',
                options: _yearOptions,
                onSelected: (value) => setState(() => _jsStartYearController.text = value),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _SearchableField(
                label: 'End Year',
                value: _jsEndYearController.text,
                hint: _jsCurrentlyPursuing ? 'Optional' : 'End Year',
                options: _yearOptions,
                onSelected: (value) => setState(() => _jsEndYearController.text = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Checkbox(
              value: _jsCurrentlyPursuing,
              onChanged: (v) => setState(() => _jsCurrentlyPursuing = v ?? false),
              activeColor: AppColors.headerYellow,
            ),
            Text('Currently Pursuing', style: AppTextStyles.bodyMedium(context)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ];
    }

    return [
      Text("Let’s Build Your Professional Story", style: AppTextStyles.headingLarge(context).copyWith(fontSize: 24)),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Fill in your details to create a strong profile.',
        style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.xxl),
      _SearchableField(
        label: 'Employment Type',
        value: _jsEmploymentTypeController.text,
        hint: 'Employment Type',
        options: const ['Fresher', 'Internship', 'Full-time', 'Part-time', 'Contract'],
        onSelected: (value) => setState(() => _jsEmploymentTypeController.text = value),
      ),
      const SizedBox(height: AppSpacing.lg),
      _SearchableField(
        label: 'Current Job Title',
        value: _jsCurrentJobTitleController.text,
        hint: 'Select job title',
        options: _jobTitleOptions,
        onSelected: (value) => setState(() => _jsCurrentJobTitleController.text = value),
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(label: 'Current Company', hint: 'Company name', controller: _jsCurrentCompanyController),
      const SizedBox(height: AppSpacing.lg),
      _SearchableField(
        label: 'Industry Type',
        value: _jsIndustryTypeController.text,
        hint: 'Select industry type',
        options: _industryTypeOptions,
        onSelected: (value) => setState(() => _jsIndustryTypeController.text = value),
      ),
      const SizedBox(height: AppSpacing.lg),
      _SearchableField(
        label: 'Total Experience',
        value: _jsTotalExperienceController.text,
        hint: 'Select experience',
        options: const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
        onSelected: (value) => setState(() => _jsTotalExperienceController.text = value),
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  bool _validateJobSeekerStep(int step) {
    final edit = _signUpArgs?.isEditProfile == true;
    if (step == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _genderController.text.trim().isEmpty) {
        _showMessage('Please fill all required personal details');
        return false;
      }
      if (!edit) {
        if (_passwordController.text.trim().isEmpty ||
            _officialEmailController.text.trim().isEmpty) {
          _showMessage('Please fill all required personal details');
          return false;
        }
        if (_passwordController.text.trim() != _officialEmailController.text.trim()) {
          _showMessage('Password and confirm password must match');
          return false;
        }
        if (_passwordController.text.trim().length < 6) {
          _showMessage('Password must be at least 6 characters');
          return false;
        }
      }
      return true;
    }
    if (step == 1) {
      if (_stateController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
        _showMessage('Please select state and city');
        return false;
      }
      return true;
    }
    if (step == 2) {
      if (_jsSchoolController.text.trim().isEmpty ||
          _jsFieldOfStudyController.text.trim().isEmpty ||
          _jsDegreeController.text.trim().isEmpty ||
          _jsStartYearController.text.trim().isEmpty) {
        _showMessage('Please fill all required education details');
        return false;
      }
      if (!_jsCurrentlyPursuing && _jsEndYearController.text.trim().isEmpty) {
        _showMessage('End year is required when not currently pursuing');
        return false;
      }
      return true;
    }
    if (step == 3) {
      if (_jsEmploymentTypeController.text.trim().isEmpty ||
          _jsCurrentJobTitleController.text.trim().isEmpty ||
          _jsCurrentCompanyController.text.trim().isEmpty ||
          _jsIndustryTypeController.text.trim().isEmpty ||
          _jsTotalExperienceController.text.trim().isEmpty) {
        _showMessage('Please fill all required professional details');
        return false;
      }
      return true;
    }
    return true;
  }

  Future<void> _submitJobSeekerRegistration(SignUpArgs? args) async {
    if (args == null || args.phone.isEmpty || args.role == null) {
      _showMessage('Missing sign-up data');
      return;
    }
    if (!_validateJobSeekerStep(3)) return;

    final identifier = (args.phone).trim();
    final phoneValue = identifier.contains('@') ? _jsPhoneController.text.trim() : identifier;
    if (phoneValue.isEmpty) {
      _showMessage('Phone field is required');
      return;
    }
    final phoneDigits = phoneValue.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 15) {
      _showMessage('Please enter a valid phone number');
      return;
    }
    final displayName = _hrDisplayName;
    final yearsExp = _jsTotalExperienceController.text.trim().replaceAll('+', '');
    setState(() => _loading = true);
    final res = await _authApi.signUpWithPhone(
      phone: phoneValue,
      name: displayName.isEmpty ? _firstNameController.text.trim() : displayName,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: args.role!,
      gender: _genderController.text.trim(),
      educationLevel: _jsDegreeController.text.trim(),
      stream: _jsFieldOfStudyController.text.trim(),
      branch: _jsSchoolController.text.trim(),
      yearsOfExperience: int.tryParse(yearsExp),
      locationPreferences: [
        if (_cityController.text.trim().isNotEmpty) _cityController.text.trim(),
        if (_stateController.text.trim().isNotEmpty) _stateController.text.trim(),
      ],
      profileImagePath: _profileImage?.path,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isOk) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
      return;
    }
    String msg = res.error ?? 'Sign up failed';
    if (res.data is Map && res.data['message'] != null) {
      msg = res.data['message'].toString();
    }
    _showMessage(msg);
  }

  Future<void> _submitJobSeekerProfileUpdate() async {
    if (!_validateJobSeekerStep(3)) return;

    final phoneValue = _jsPhoneController.text.trim();
    if (phoneValue.isEmpty) {
      _showMessage('Phone field is required');
      return;
    }
    final phoneDigits = phoneValue.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 15) {
      _showMessage('Please enter a valid phone number');
      return;
    }

    final displayName = _hrDisplayName;
    setState(() => _loading = true);

    if (_profileImage != null) {
      final up = await _profileApi.uploadProfileImage(_profileImage!);
      if (!mounted) return;
      if (up.isOk && up.data != null) {
        dynamic body = up.data;
        if (body is Map && body['data'] is Map) body = body['data'];
        final url = body is Map ? body['image']?.toString() : null;
        if (url != null && url.isNotEmpty) {
          _editProfileImageUrl = url;
          await AuthStorage.setProfileImageUrl(url);
        }
      } else {
        setState(() => _loading = false);
        _showMessage(up.error ?? 'Image upload failed');
        return;
      }
    }

    final userBody = <String, dynamic>{
      'name': displayName.isEmpty ? _firstNameController.text.trim() : displayName,
      'phone': phoneValue,
    };
    if (_emailController.text.trim().isNotEmpty) {
      userBody['email'] = _emailController.text.trim();
    }

    final durationTo =
        _jsCurrentlyPursuing ? 'Present' : _jsEndYearController.text.trim();

    final profilePayload = <String, dynamic>{
      'address': '',
      'state': _stateController.text.trim(),
      'city': _cityController.text.trim(),
      'job_title': _jsCurrentJobTitleController.text.trim(),
      'qualification': _jsDegreeController.text.trim(),
      'stream': _jsFieldOfStudyController.text.trim(),
      'college_name': _jsSchoolController.text.trim(),
      'university_board': '',
      'experience_level': _jsTotalExperienceController.text.trim(),
      'company_name': _jsCurrentCompanyController.text.trim(),
      'employment_type': _jsEmploymentTypeController.text.trim(),
      'industry_type': _jsIndustryTypeController.text.trim(),
      'duration_from': _jsStartYearController.text.trim(),
      'duration_to': durationTo,
      'skills': '',
    };

    final r1 = await _profileApi.updateUserProfile(userBody);
    final r2 = await _profileApi.updateProfile(<String, dynamic>{
      'job_seeker_profile': profilePayload,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (r1.isOk && r2.isOk) {
      await AuthStorage.setUserName(displayName.isEmpty ? _firstNameController.text.trim() : displayName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
      return;
    }
    final err = r2.error ?? r1.error ?? 'Update failed';
    _showMessage(err);
  }

  String get _hrDisplayName {
    final title = _titleController.text.trim();
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    return [title, first, last].where((e) => e.isNotEmpty).join(' ');
  }

  List<String> get _parsedSkills => _skillsController.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  bool _validateHrStep(int step) {
    if (step == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _genderController.text.trim().isEmpty) {
        _showMessage('Please fill all required details in step 1');
        return false;
      }
      if (_passwordController.text.length < 6) {
        _showMessage('Password must be at least 6 characters');
        return false;
      }
      return true;
    }
    if (step == 1) {
      if (_jobTitleController.text.trim().isEmpty ||
          _companyNameController.text.trim().isEmpty ||
          _employmentTypeController.text.trim().isEmpty ||
          _totalExperienceController.text.trim().isEmpty ||
          _industryTypeController.text.trim().isEmpty) {
        _showMessage('Please fill all required details in step 2');
        return false;
      }
      return true;
    }
    return true;
  }

  bool _validateHrBeforeSubmit() {
    if (!_validateHrStep(0) || !_validateHrStep(1)) return false;
    if (_stateController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      _showMessage('Please select state and city');
      return false;
    }
    if (_companyNameController.text.trim().isEmpty ||
        _jobTitleController.text.trim().isEmpty) {
      _showMessage('Company name and Job title are required for HR');
      return false;
    }
    return true;
  }

  void _goToNextHrStep() {
    if (!_validateHrStep(_hrCurrentStep)) return;
    setState(() => _hrCurrentStep += 1);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickProfileImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _profileImage = File(picked.path));
  }

  List<Widget> _buildHrStepContent(SignUpArgs? args) {
    if (_hrCurrentStep == 0) {
      return [
        Center(
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.textFieldBackground,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.textSecondary,
                        )
                      : null,
                ),
                Container(
                  height: 28,
                  width: 28,
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
                label: null,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone', style: AppTextStyles.bodyMedium(context)),
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
              child: Text(
                args?.phone ?? '',
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Email',
          hint: 'you@example.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Password',
          hint: 'Min 6 characters',
          controller: _passwordController,
          obscureText: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Gender', style: AppTextStyles.bodyMedium(context)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: ['Male', 'Female', 'Other']
              .map(
                (gender) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _genderController.text = gender.toLowerCase(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: _genderController.text == gender.toLowerCase()
                              ? AppColors.headerYellow
                              : AppColors.textFieldBackground,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
                          ),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Text(
                          gender,
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

    if (_hrCurrentStep == 1) {
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
          controller: _companyNameController,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SearchableField(
          label: null,
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
          controller: _educationDetailsController,
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
          controller: _industryTypeController,
        ),
        const SizedBox(height: AppSpacing.lg),
      ];
    }

    final state = _stateController.text;
    final cities = _stateCityMap[state] ?? const <String>[];
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
        label: null,
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
        label: null,
        value: _cityController.text,
        hint: 'City',
        options: cities,
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

  Future<void> _pickOrganizationLogo() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _organisationLogo = File(picked.path));
  }

  Future<void> _pickDocument(String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final fileName = result.files.single.name;
    setState(() => _orgDocumentNames[key] = fileName);
  }

  Future<void> _verifyOrganisationGst() async {
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

  String _organisationAppBarTitle() {
    switch (_organisationCurrentStep) {
      case 0:
        return 'Organization Profile';
      case 1:
        return 'Organization Details';
      case 2:
        return 'Location Details';
      case 3:
        return 'Contact Person Details';
      default:
        return 'Organization';
    }
  }

  Future<void> _openOrganizationMapPicker() async {
    final r = await Navigator.push<OrganizationLocationMapResult>(
      context,
      MaterialPageRoute(builder: (_) => const OrganizationMapPickerPage()),
    );
    if (r == null || !mounted) return;
    setState(() {
      _orgAddress1Controller.text = r.formattedAddress;
      if (r.city.isNotEmpty) _orgCityController.text = r.city;
      if (r.state.isNotEmpty) _orgStateController.text = r.state;
      if (r.pinCode.isNotEmpty) _orgPinCodeController.text = r.pinCode;
    });
  }

  Future<void> _useOrgCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Please turn on location services');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is required');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    final geo = GoogleGeocodingService();
    final r = await geo.reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted || r == null) {
      if (mounted) _showMessage('Could not resolve address');
      return;
    }
    setState(() {
      _orgAddress1Controller.text = r.formattedAddress;
      if (r.city.isNotEmpty) _orgCityController.text = r.city;
      if (r.state.isNotEmpty) _orgStateController.text = r.state;
      if (r.pinCode.isNotEmpty) _orgPinCodeController.text = r.pinCode;
    });
  }

  List<Widget> _buildOrganisationStepContent(SignUpArgs? args) {
    final edit = args?.isEditProfile == true;
    final state = _orgStateController.text;
    final cities = _stateCityMap[state] ?? const <String>[];
    final logoNet = _absoluteImageUrl(_editOrganisationImageUrl);

    Widget whoRadio(String value, String label) {
      final selected = _orgEntityType == value;
      return InkWell(
        onTap: () => setState(() => _orgEntityType = value),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.headerYellow : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium(context))),
            ],
          ),
        ),
      );
    }

    switch (_organisationCurrentStep) {
      case 0:
        return [
          Center(
            child: GestureDetector(
              onTap: _pickOrganizationLogo,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.textFieldBackground,
                    backgroundImage: _organisationLogo != null
                        ? FileImage(_organisationLogo!)
                        : (logoNet.isNotEmpty ? NetworkImage(logoNet) : null),
                    child: _organisationLogo == null && logoNet.isEmpty
                        ? const Icon(Icons.person_outline, size: 44, color: AppColors.textSecondary)
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
          AppTextField(label: 'Company Name', hint: 'Registered name', controller: _orgCompanyNameController),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _legalNameChecked,
                onChanged: (v) => setState(() => _legalNameChecked = v ?? false),
                activeColor: AppColors.headerYellow,
              ),
              Expanded(child: Text('Legal Name', style: AppTextStyles.bodyMedium(context))),
            ],
          ),
          if (_legalNameChecked) ...[
            AppTextField(label: null, hint: 'Legal entity name', controller: _orgLegalEntityNameController),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('Company Description', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _orgDescriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your organization',
              filled: true,
              fillColor: AppColors.textFieldBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Website Url',
            hint: 'https://example.com',
            controller: _orgWebsiteController,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Who you are?', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          whoRadio('direct', 'Direct Organization'),
          whoRadio('placement', 'Placement Consultancy'),
          whoRadio('contractor', 'Contractor'),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Email',
            hint: 'sayalirane@gmail.com',
            controller: _orgOfficialEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
          if (!edit) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Password',
              hint: 'Yellowpin@123',
              controller: _passwordController,
              obscureText: _obscureOrgPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscureOrgPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureOrgPassword = !_obscureOrgPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: _orgPasswordConfirmController,
              obscureText: _obscureOrgPasswordConfirm,
              suffixIcon: IconButton(
                icon: Icon(_obscureOrgPasswordConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureOrgPasswordConfirm = !_obscureOrgPasswordConfirm),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ];
      case 1:
        return [
          Text(
            'Tell Us About Your Organization',
            style: AppTextStyles.headingLarge(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add company details to get started',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
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
          _SearchableField(
            label: 'Business Type',
            value: _orgBusinessTypeController.text,
            hint: 'Select business type',
            options: const [
              'Private Limited',
              'Public Limited',
              'LLP',
              'Partnership',
              'Sole Proprietorship',
              'Government',
              'NGO',
            ],
            onSelected: (value) => setState(() => _orgBusinessTypeController.text = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Year Of Establishment',
            hint: 'e.g. 2015',
            controller: _orgYearEstablishmentController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SearchableField(
            label: 'No Of Employment',
            value: _orgEmployeeCountController.text,
            hint: 'Select range',
            options: const ['1–10', '11–50', '51–200', '201–500', '500+'],
            onSelected: (value) => setState(() => _orgEmployeeCountController.text = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Gst No', style: AppTextStyles.bodyMedium(context)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(label: null, hint: 'GST number', controller: _gstNumberController),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: TextButton(
                  onPressed: _verifyOrganisationGst,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.headerYellow,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                  ),
                  child: Text(_gstVerified ? 'OK' : 'Verify'),
                ),
              ),
            ],
          ),
          if (_gstVerified)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Validated', style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.white)),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Pan No', hint: 'PAN number', controller: _orgPanNoController),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Checkbox(
                value: _hasTradeName,
                onChanged: (v) => setState(() => _hasTradeName = v ?? false),
                activeColor: AppColors.headerYellow,
              ),
              Expanded(child: Text('Trade name (optional)', style: AppTextStyles.bodyMedium(context))),
            ],
          ),
          if (_hasTradeName) ...[
            AppTextField(label: null, hint: 'Trade name', controller: _orgTradeNameController),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('Upload Documents', style: AppTextStyles.headingMedium(context).copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.1,
            children: [
              _buildOrgDocCell('Gst', Icons.add),
              _buildOrgDocCell('Pan Card', Icons.add),
              _buildOrgDocCell('COI', Icons.add),
              _buildOrgDocCell('Other', Icons.add),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ];
      case 2:
        return [
          Text(
            "Let's Set Your Location",
            style: AppTextStyles.headingLarge(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your location to get relevant opportunities.',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: _useOrgCurrentLocation,
            child: Row(
              children: [
                Text('Use my current location', style: AppTextStyles.link(context)),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.north_east, size: 18, color: AppColors.textPrimary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _openOrganizationMapPicker,
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('Pick on map'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            label: 'Address 1',
            hint: 'Office / Building / Street',
            controller: _orgAddress1Controller,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Address 2',
            hint: 'Area / Landmark (optional)',
            controller: _orgAddress2Controller,
          ),
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
          AppTextField(
            label: 'PinCode',
            hint: 'Postal code',
            controller: _orgPinCodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.xl),
        ];
      case 3:
        return [
          Text(
            "Let's Build Your Professional Story",
            style: AppTextStyles.headingLarge(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fill in your details to create a strong profile.',
            style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(label: 'Contact Person Name', hint: 'Name', controller: _orgHrPersonNameController),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(label: 'Designation', hint: 'Role', controller: _orgContactDesignationController),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Email',
            hint: 'you@company.com',
            controller: _orgOfficialEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Phone',
            hint: 'Phone number',
            controller: _orgPhoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.xl),
        ];
      default:
        return [];
    }
  }

  Widget _buildOrgDocCell(String key, IconData icon) {
    final name = _orgDocumentNames[key];
    return InkWell(
      onTap: () => _pickDocument(key),
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.textFieldBackground,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.headerYellow.withValues(alpha: 0.5), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name ?? key,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
    this.allowCustomEntry = false,
    this.customSubmitLabel = 'Use this value',
  });

  final String? label;
  final String value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool allowCustomEntry;
  final String customSubmitLabel;

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
              builder: (_) => _SearchBottomSheet(
                options: options,
                title: hint,
                allowCustomEntry: allowCustomEntry,
                customSubmitLabel: customSubmitLabel,
              ),
            );
            if (selected != null && selected.isNotEmpty) {
              onSelected(selected);
            }
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
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  const _SearchBottomSheet({
    required this.options,
    required this.title,
    required this.allowCustomEntry,
    required this.customSubmitLabel,
  });

  final List<String> options;
  final String title;
  final bool allowCustomEntry;
  final String customSubmitLabel;

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
          if (widget.allowCustomEntry &&
              _searchController.text.trim().isNotEmpty &&
              !widget.options
                  .map((e) => e.toLowerCase())
                  .contains(_searchController.text.trim().toLowerCase()))
            ListTile(
              leading: const Icon(Icons.add),
              title: Text('${widget.customSubmitLabel}: "${_searchController.text.trim()}"'),
              onTap: () => Navigator.pop(context, _searchController.text.trim()),
            ),
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

const List<String> _schoolCollegeOptions = [
  'Savitribai Phule Pune University',
  'Mumbai University',
  'Delhi University',
  'IIT Bombay',
  'IIT Delhi',
  'IIM Ahmedabad',
  'Symbiosis International University',
  'MIT World Peace University',
  'VIT Pune',
  'Christ University',
];

const List<String> _fieldOfStudyOptions = [
  'Engineering',
  'MBA',
  'Commerce',
  'Arts',
  'Science',
  'Computer Applications',
];

const Map<String, List<String>> _degreeByField = {
  'Engineering': ['Bachelors (B.E/B.Tech)', 'Masters (M.E/M.Tech)'],
  'MBA': ['Masters (MBA/PGDM)'],
  'Commerce': ['Bachelors (B.Com)', 'Masters (M.Com)'],
  'Arts': ['Bachelors (B.A)', 'Masters (M.A)'],
  'Science': ['Bachelors (B.Sc)', 'Masters (M.Sc)'],
  'Computer Applications': ['Bachelors (BCA)', 'Masters (MCA)'],
};

final List<String> _yearOptions = List.generate(41, (i) => (DateTime.now().year - i).toString());

const List<String> _jobTitleOptions = [
  'Software Engineer',
  'Senior Software Engineer',
  'Frontend Developer',
  'Backend Developer',
  'Full Stack Developer',
  'Mobile App Developer',
  'DevOps Engineer',
  'Data Analyst',
  'Data Scientist',
  'UI/UX Designer',
  'Business Analyst',
  'Product Manager',
  'Project Manager',
  'HR Executive',
  'HR Manager',
  'Marketing Executive',
  'Sales Executive',
  'Operations Executive',
  'Finance Executive',
  'Teacher',
];

const List<String> _industryTypeOptions = [
  'Information Technology',
  'Software & Services',
  'Banking & Financial Services',
  'Insurance',
  'Healthcare',
  'Pharmaceuticals',
  'Education',
  'E-learning',
  'Manufacturing',
  'Automobile',
  'Construction',
  'Real Estate',
  'Retail',
  'E-commerce',
  'Logistics & Supply Chain',
  'Telecommunications',
  'Media & Entertainment',
  'Hospitality',
  'Consulting',
  'Government / Public Sector',
];

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
