/// Base URL for the Laravel API (live server).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://yellowpin.bizz-manager.com';
  static const String apiPrefix = '/api/v1';

  static String get apiBaseUrl => '$baseUrl$apiPrefix';
}
