import 'auth_storage.dart';
import 'api_client.dart';

/// Courses API: list, get by id, create (auth required for create).
class CoursesApi {
  CoursesApi() : _client = ApiClient(token: null);

  final ApiClient _client;

  Future<ApiClient> _clientWithToken() async {
    final token = await AuthStorage.getToken();
    return ApiClient(token: token);
  }

  /// GET /courses — list courses. Query: search, stream, mode, per_page, page.
  Future<ApiResponse> getCourses({
    String? search,
    String? stream,
    String? mode,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (stream != null && stream.isNotEmpty) query['stream'] = stream;
    if (mode != null && mode.isNotEmpty) query['mode'] = mode;
    return _client.get('/courses', queryParams: query);
  }

  /// GET /courses/{id} — fetch a single course (with user).
  Future<ApiResponse> getCourse(int id) async {
    final client = await _clientWithToken();
    return client.get('/courses/$id');
  }

  /// POST /courses — create a course (institute only).
  Future<ApiResponse> createCourse(Map<String, dynamic> body) async {
    final client = await _clientWithToken();
    return client.post('/courses', body: body);
  }

  /// POST /courses/{id}/interested — mark current user as interested.
  Future<ApiResponse> markInterested(int id) async {
    final client = await _clientWithToken();
    return client.post('/courses/$id/interested', body: {});
  }
}
