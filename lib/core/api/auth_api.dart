import 'api_client.dart';
import 'auth_storage.dart';

/// Auth API: sign-up (phone OTP flow), sign-in, etc.
class AuthApi {
  AuthApi() : _client = ApiClient();

  final ApiClient _client;

  /// POST /sign-in-with-phone — send OTP to phone for selected role.
  Future<ApiResponse> loginWithPhoneOTP(String phone, String role) async {
    return _client.post(
      '/sign-in-with-phone',
      body: {'phone': phone, 'role': role},
    );
  }

  /// POST /verify-user-phone — verify OTP for selected role and sign in.
  Future<ApiResponse> verifyLoginOtp(
    String phone,
    String otp,
    String role,
  ) async {
    final res = await _client.post(
      '/verify-user-phone',
      body: {'phone': phone, 'otp': otp, 'role': role},
    );
    if (res.isOk && res.data is Map) await _saveTokenAndUser(res.data);
    return res;
  }

  /// POST /sign-in-with-email-password — role-isolated email/password sign in.
  Future<ApiResponse> loginWithEmailPassword(
    String email,
    String password,
    String role,
  ) async {
    final res = await _client.post(
      '/sign-in-with-email-password',
      body: {'email': email, 'password': password, 'role': role},
    );
    if (res.isOk && res.data is Map) await _saveTokenAndUser(res.data);
    return res;
  }

  static Future<void> _saveTokenAndUser(Map data) async {
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await AuthStorage.setToken(token);
      final user = data['data'];
      if (user is Map) {
        if (user['name'] != null)
          await AuthStorage.setUserName(user['name'].toString());
        if (user['role'] != null)
          await AuthStorage.setUserRole(user['role'].toString());
      }
    }
  }

  /// GET /sign-out — revoke token on server. Call clearToken() after; this method does not clear local storage.
  Future<ApiResponse> signOut() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      return ApiResponse.success(data: {'message': 'Already signed out.'});
    }
    final client = ApiClient(token: token);
    return client.get('/sign-out');
  }

  /// Clear local auth (token and user name). Call after signOut() or when logging out offline.
  static Future<void> clearAuth() async {
    await AuthStorage.clearToken();
  }

  /// POST /verify-with-phone — send OTP to phone/email for sign-up in selected role.
  Future<ApiResponse> verifyWithPhone(String identifier, String role) async {
    final isEmail = identifier.contains('@');
    final body = isEmail
        ? <String, dynamic>{
            'email': identifier,
            // Backward-compatible key for backends still validating `phone` as required.
            'phone': identifier,
            'identifier': identifier,
            'role': role,
          }
        : <String, dynamic>{
            'phone': identifier,
            'identifier': identifier,
            'role': role,
          };
    return _client.post('/verify-with-phone', body: body);
  }

  /// POST /verify-otp — verify OTP for sign-up in selected role.
  Future<ApiResponse> verifyOtp(
    String identifier,
    String otp,
    String role,
  ) async {
    final isEmail = identifier.contains('@');
    final body = isEmail
        ? <String, dynamic>{
            'email': identifier,
            // Backward-compatible key for backends still validating `phone` as required.
            'phone': identifier,
            'identifier': identifier,
            'otp': otp,
            'role': role,
          }
        : <String, dynamic>{
            'phone': identifier,
            'identifier': identifier,
            'otp': otp,
            'role': role,
          };
    return _client.post('/verify-otp', body: body);
  }

  /// POST /sign-up — register with phone (after OTP verified). Role: hr | organisation | institute | job_seeker.
  Future<ApiResponse> signUpWithPhone({
    required String phone,
    required String name,
    required String email,
    required String password,
    required String role,
    // HR
    String? companyName,
    String? jobTitle,
    String? employmentType,
    String? designation,
    String? industryType,
    int? totalExperience,
    String? gender,
    String? officialEmail,
    bool? hiringAuthorityConfirmed,
    String? educationDetails,
    List<String>? hrSkills,
    String? hrState,
    String? hrCity,
    // Organisation
    String? gstNumber,
    String? cin,
    String? companyAddress,
    String? companyWebsite,
    String? panNo,
    String? organizationPhone,
    String? hrPersonName,
    String? tradeName,
    String? state,
    String? city,
    String? authorizedSignatoryName,
    String? authorizedSignatoryEmail,
    // Institute
    String? instituteName,
    String? affiliationUniversity,
    String? tpoName,
    String? tpoEmail,
    String? address,
    String? gstNumberInstitute,
    int? studentStrength,
    List<String>? streamsOffered,
    // Job seeker
    String? educationLevel,
    String? stream,
    String? branch,
    List<String>? skills,
    int? yearsOfExperience,
    List<String>? locationPreferences,
    int? instituteId,
    String? profileImagePath,
  }) async {
    final isEmailIdentifier = phone.contains('@');
    final resolvedEmail = email.trim().isNotEmpty
        ? email.trim()
        : (isEmailIdentifier ? phone.trim() : '');
    final resolvedPhone = !isEmailIdentifier
        ? phone.trim()
        : (organizationPhone != null && organizationPhone.trim().isNotEmpty
              ? organizationPhone.trim()
              : null);
    final body = <String, dynamic>{
      if (resolvedPhone != null && resolvedPhone.isNotEmpty)
        'phone': resolvedPhone,
      'name': name,
      'email': resolvedEmail,
      'password': password,
      'role': role,
    };
    if (role == 'hr') {
      body['company_name'] = companyName ?? '';
      body['job_title'] = jobTitle ?? '';
      if (employmentType != null && employmentType.isNotEmpty) {
        body['employment_type'] = employmentType;
      }
      if (designation != null && designation.isNotEmpty)
        body['designation'] = designation;
      if (industryType != null && industryType.isNotEmpty)
        body['industry_type'] = industryType;
      if (totalExperience != null) body['total_experience'] = totalExperience;
      if (gender != null && gender.isNotEmpty) body['gender'] = gender;
      if (officialEmail != null && officialEmail.isNotEmpty)
        body['official_email'] = officialEmail;
      if (educationDetails != null && educationDetails.isNotEmpty)
        body['education_details'] = educationDetails;
      if (hrSkills != null && hrSkills.isNotEmpty) body['skills'] = hrSkills;
      if (hrState != null && hrState.isNotEmpty) body['state'] = hrState;
      if (hrCity != null && hrCity.isNotEmpty) body['city'] = hrCity;
      body['hiring_authority_confirmed'] = hiringAuthorityConfirmed ?? false;
    }
    if (role == 'organisation') {
      if (companyName != null) body['company_name'] = companyName;
      if (gstNumber != null) body['gst_number'] = gstNumber;
      if (tradeName != null) body['trade_name'] = tradeName;
      if (cin != null) body['cin'] = cin;
      if (companyAddress != null) body['company_address'] = companyAddress;
      if (companyWebsite != null) body['company_website'] = companyWebsite;
      if (panNo != null) body['pan_no'] = panNo;
      if (organizationPhone != null)
        body['organization_phone'] = organizationPhone;
      if (hrPersonName != null)
        body['authorized_signatory_name'] = hrPersonName;
      if (state != null) body['state'] = state;
      if (city != null) body['city'] = city;
      if (authorizedSignatoryName != null)
        body['authorized_signatory_name'] = authorizedSignatoryName;
      if (authorizedSignatoryEmail != null)
        body['authorized_signatory_email'] = authorizedSignatoryEmail;
    }
    if (role == 'institute') {
      if (instituteName != null) body['institute_name'] = instituteName;
      if (affiliationUniversity != null)
        body['affiliation_university'] = affiliationUniversity;
      if (tpoName != null) body['tpo_name'] = tpoName;
      if (tpoEmail != null) body['tpo_email'] = tpoEmail;
      if (officialEmail != null) body['official_email'] = officialEmail;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (gstNumberInstitute != null) body['gst_number'] = gstNumberInstitute;
      if (studentStrength != null) body['student_strength'] = studentStrength;
      if (streamsOffered != null) body['streams_offered'] = streamsOffered;
    }
    if (role == 'job_seeker') {
      if (gender != null) body['gender'] = gender;
      if (educationLevel != null) body['education_level'] = educationLevel;
      if (stream != null) body['stream'] = stream;
      if (branch != null) body['branch'] = branch;
      if (skills != null) body['skills'] = skills;
      if (yearsOfExperience != null)
        body['years_of_experience'] = yearsOfExperience;
      if (locationPreferences != null)
        body['location_preferences'] = locationPreferences;
      if (instituteId != null) body['institute_id'] = instituteId;
    }
    ApiResponse res;
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      final fields = <String, String>{};
      body.forEach((key, value) {
        if (value == null) return;
        if (value is List) {
          for (var i = 0; i < value.length; i++) {
            fields['$key[$i]'] = value[i].toString();
          }
          return;
        }
        if (value is bool) {
          fields[key] = value ? '1' : '0';
          return;
        }
        fields[key] = value.toString();
      });
      res = await _client.postMultipart(
        '/sign-up',
        fields: fields,
        filePaths: {'profile_image': profileImagePath},
      );
    } else {
      res = await _client.post('/sign-up', body: body);
    }
    if (res.isOk && res.data is Map) await _saveTokenAndUser(res.data as Map);
    return res;
  }

  /// POST /verify-gst — verify organisation GST number.
  Future<ApiResponse> verifyGstNumber(String gstNumber) async {
    return _client.post('/verify-gst', body: {'gst_number': gstNumber});
  }
}
