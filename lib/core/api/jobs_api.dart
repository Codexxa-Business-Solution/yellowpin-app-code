import 'auth_storage.dart';
import 'api_client.dart';

/// Jobs API: list (posted/applied), create job (requires auth).
class JobsApi {
  JobsApi() : _client = ApiClient(token: null);

  final ApiClient _client;

  Future<ApiClient> _clientWithToken() async {
    final token = await AuthStorage.getToken();
    return ApiClient(token: token);
  }

  /// GET /jobs/{id} — fetch a single job by ID (with user, institutes).
  Future<ApiResponse> getJob(int id) async {
    final client = await _clientWithToken();
    return client.get('/jobs/$id');
  }

  /// GET /jobs — list jobs. For HR/Organisation returns their posted jobs. Query: status, job_type, search, per_page, page.
  Future<ApiResponse> getJobs({
    String? status,
    String? jobType,
    String? search,
    int page = 1,
    int perPage = 15,
    bool mine = false,
  }) async {
    final client = await _clientWithToken();
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (mine) 'mine': '1',
    };
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (jobType != null && jobType.isNotEmpty) query['job_type'] = jobType;
    if (search != null && search.isNotEmpty) query['search'] = search;
    return client.get('/jobs', queryParams: query);
  }

  /// GET /applications — list job applications. For HR/Organisation: applications to their jobs. For Job Seeker: their applications.
  Future<ApiResponse> getApplications({int page = 1, int perPage = 15}) async {
    final client = await _clientWithToken();
    return client.get(
      '/applications',
      queryParams: {'page': page.toString(), 'per_page': perPage.toString()},
    );
  }

  /// POST /jobs — create a job post (HR/Organisation only).
  /// If [attachmentPath] is provided, sends multipart/form-data with a file
  /// field called "attachment". Otherwise sends JSON body.
  Future<ApiResponse> createJob(
    Map<String, dynamic> body, {
    String? attachmentPath,
  }) async {
    final client = await _clientWithToken();
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      final fields = <String, String>{};
      body.forEach((key, value) {
        if (value == null) return;
        // visible_to_institute_ids must be an array in Laravel; when we don't
        // have any IDs, skip sending this field completely to avoid the
        // "must be array" validation error for string values in multipart.
        if (key == 'visible_to_institute_ids' &&
            value is List &&
            value.isEmpty) {
          return;
        }
        if (value is bool) {
          fields[key] = value ? '1' : '0';
        } else {
          fields[key] = value.toString();
        }
      });
      return client.postMultipart(
        '/jobs',
        fields: fields,
        filePaths: {'attachment': attachmentPath},
      );
    }
    return client.post('/jobs', body: body);
  }

  /// PUT /jobs/{id} — update a job post (HR/Organisation only).
  /// If [attachmentPath] is provided, sends multipart/form-data, otherwise JSON.
  Future<ApiResponse> updateJob(
    int id,
    Map<String, dynamic> body, {
    String? attachmentPath,
  }) async {
    final client = await _clientWithToken();
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      final fields = <String, String>{};
      body.forEach((key, value) {
        if (value == null) return;
        if (key == 'visible_to_institute_ids' &&
            value is List &&
            value.isEmpty) {
          return;
        }
        if (value is bool) {
          fields[key] = value ? '1' : '0';
        } else {
          fields[key] = value.toString();
        }
      });
      return client.putMultipart(
        '/jobs/$id',
        fields: fields,
        filePaths: {'attachment': attachmentPath},
      );
    }
    return client.put('/jobs/$id', body: body);
  }

  /// DELETE /jobs/{id} — delete a job post (HR/Organisation only).
  Future<ApiResponse> deleteJob(int id) async {
    final client = await _clientWithToken();
    return client.delete('/jobs/$id');
  }
}
