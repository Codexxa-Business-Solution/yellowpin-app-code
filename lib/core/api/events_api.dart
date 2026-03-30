import 'auth_storage.dart';
import 'api_client.dart';

/// Events API: list, get by id, create (auth required for create).
class EventsApi {
  EventsApi() : _client = ApiClient(token: null);

  final ApiClient _client;

  Future<ApiClient> _clientWithToken() async {
    final token = await AuthStorage.getToken();
    return ApiClient(token: token);
  }

  /// GET /events — list events. Query: event_type, location, search, per_page, page.
  Future<ApiResponse> getEvents({
    String? eventType,
    String? location,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (eventType != null && eventType.isNotEmpty) query['event_type'] = eventType;
    if (location != null && location.isNotEmpty) query['location'] = location;
    if (search != null && search.isNotEmpty) query['search'] = search;
    return _client.get('/events', queryParams: query);
  }

  /// GET /events/my — list events created by the logged-in user (auth required).
  /// [status]: 'active' = upcoming/ongoing, 'completed' = past events.
  Future<ApiResponse> getMyEvents({
    String? eventType,
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final client = await _clientWithToken();
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (eventType != null && eventType.isNotEmpty) query['event_type'] = eventType;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    return client.get('/events/my', queryParams: query);
  }

  /// GET /events/{id} — fetch a single event (with user).
  Future<ApiResponse> getEvent(int id) async {
    final client = await _clientWithToken();
    return client.get('/events/$id');
  }

  /// POST /events — create an event. If [coverPath] is set, sends multipart with cover image.
  Future<ApiResponse> createEvent(Map<String, dynamic> body, {String? coverPath}) async {
    final client = await _clientWithToken();
    if (coverPath != null && coverPath.isNotEmpty) {
      final fields = <String, String>{};
      body.forEach((key, value) {
        if (value == null) return;
        if (value is bool) {
          fields[key] = value ? '1' : '0';
        } else {
          fields[key] = value.toString();
        }
      });
      return client.postMultipart('/events', fields: fields, filePaths: {'cover': coverPath});
    }
    return client.post('/events', body: body);
  }

  /// PUT /events/{id} — update event (owner only). Optional [coverPath] for new cover image.
  Future<ApiResponse> updateEvent(int id, Map<String, dynamic> body, {String? coverPath}) async {
    final client = await _clientWithToken();
    if (coverPath != null && coverPath.isNotEmpty) {
      final fields = <String, String>{};
      body.forEach((key, value) {
        if (value == null) return;
        if (value is bool) {
          fields[key] = value ? '1' : '0';
        } else {
          fields[key] = value.toString();
        }
      });
      return client.putMultipart('/events/$id', fields: fields, filePaths: {'cover': coverPath});
    }
    return client.put('/events/$id', body: body);
  }

  /// DELETE /events/{id} — delete event (owner only).
  Future<ApiResponse> deleteEvent(int id) async {
    final client = await _clientWithToken();
    return client.delete('/events/$id');
  }

  /// POST /events/{id}/register — register or mark interested.
  Future<ApiResponse> register(int id) async {
    final client = await _clientWithToken();
    return client.post('/events/$id/register', body: {});
  }
}
