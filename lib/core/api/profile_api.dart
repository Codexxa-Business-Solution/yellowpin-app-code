import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_storage.dart';
import 'api_client.dart';
import 'api_config.dart';

/// Profile API: get and update user profile (requires auth).
class ProfileApi {
  ProfileApi() : _client = ApiClient(token: null);

  final ApiClient _client;

  Future<ApiClient> _clientWithToken() async {
    final token = await AuthStorage.getToken();
    return ApiClient(token: token);
  }

  /// GET /profile — fetch current user with role profile (hr_profile, job_seeker_profile, etc.).
  Future<ApiResponse> getProfile() async {
    final client = await _clientWithToken();
    return client.get('/profile');
  }

  /// POST /profile — update user basics (name, email, phone, image, bio).
  Future<ApiResponse> updateUserProfile(Map<String, dynamic> body) async {
    final client = await _clientWithToken();
    return client.post('/profile', body: body);
  }

  /// POST /profile/upload-image — upload profile image (multipart). Returns { image: url }.
  Future<ApiResponse> uploadProfileImage(File imageFile) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/profile/upload-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      dynamic body;
      try {
        body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        body = response.body;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(statusCode: response.statusCode, data: body);
      }
      final message = body is Map && body['message'] != null
          ? body['message'].toString()
          : response.body;
      return ApiResponse.error(message, statusCode: response.statusCode, data: body);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// PUT /profile — update profile. For HR: job_title, company_name, total_experience, etc.
  Future<ApiResponse> updateProfile(Map<String, dynamic> body) async {
    final client = await _clientWithToken();
    return client.put('/profile', body: body);
  }
}
