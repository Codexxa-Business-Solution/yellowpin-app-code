import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Central HTTP client for Laravel API. Adds base URL and optional Bearer token.
class ApiClient {
  ApiClient({this.token});

  String? token;

  static const Duration _timeout = Duration(seconds: 30);

  String get _base => ApiConfig.apiBaseUrl;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  String _networkErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('timeout') || s.contains('socketexception') || s.contains('connection refused')) {
      return 'Cannot reach server. Ensure Laravel is running: php artisan serve --host=0.0.0.0. '
          'On a physical device, set ApiConfig.useCustomHost to your PC IP.';
    }
    return e.toString();
  }

  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    final uri = queryParams != null && queryParams.isNotEmpty
        ? Uri.parse('$_base$path').replace(queryParameters: queryParams)
        : Uri.parse('$_base$path');
    try {
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      return _handleResponse(r);
    } catch (e) {
      return ApiResponse.error(_networkErrorMessage(e));
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_base$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(r);
    } catch (e) {
      return ApiResponse.error(_networkErrorMessage(e));
    }
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final r = await http
          .put(
            Uri.parse('$_base$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(r);
    } catch (e) {
      return ApiResponse.error(_networkErrorMessage(e));
    }
  }

  Future<ApiResponse> delete(String path) async {
    try {
      final r = await http.delete(Uri.parse('$_base$path'), headers: _headers).timeout(_timeout);
      return _handleResponse(r);
    } catch (e) {
      return ApiResponse.error(_networkErrorMessage(e));
    }
  }

  ApiResponse _handleResponse(http.Response r) {
    final body = r.body.isNotEmpty ? _tryDecode(r.body) : null;
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return ApiResponse.success(statusCode: r.statusCode, data: body);
    }
    final message = _extractErrorMessage(body, r.body);
    return ApiResponse.error(
      message,
      statusCode: r.statusCode,
      data: body,
    );
  }

  /// Laravel returns { "message": "...", "errors": { "field": ["msg"] } }. Combine into one string.
  String _extractErrorMessage(dynamic body, String rawBody) {
    if (body is! Map) return rawBody.isNotEmpty ? rawBody : 'Request failed';
    final msg = body['message'];
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      final text = first is List && first.isNotEmpty ? first.first.toString() : first.toString();
      return msg != null ? '$msg $text' : text;
    }
    if (msg != null) return msg.toString();
    return rawBody.isNotEmpty ? rawBody : 'Request failed';
  }

  static dynamic _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }
}

extension ApiClientMultipart on ApiClient {
  Map<String, String> get _multipartHeaders => {
        'Accept': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<ApiResponse> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? filePaths,
  }) async {
    try {
      final uri = Uri.parse('$_base$path');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders);
      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value));
        }
      }
      final streamed = await request.send().timeout(ApiClient._timeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_networkErrorMessage(e));
    }
  }

  Future<ApiResponse> putMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? filePaths,
  }) async {
    // Laravel treats POST with _method=PUT as a PUT request. This is the
    // easiest way to send multipart form-data for updates.
    final mergedFields = <String, String>{'_method': 'PUT', ...?fields};
    return postMultipart(path, fields: mergedFields, filePaths: filePaths);
  }
}

class ApiResponse {
  ApiResponse._({this.statusCode, this.data, this.error});

  factory ApiResponse.success({int? statusCode, dynamic data}) {
    return ApiResponse._(statusCode: statusCode, data: data);
  }

  factory ApiResponse.error(String error, {int? statusCode, dynamic data}) {
    return ApiResponse._(statusCode: statusCode, data: data, error: error);
  }

  final int? statusCode;
  final dynamic data;
  final String? error;

  bool get isOk => error == null;
}
