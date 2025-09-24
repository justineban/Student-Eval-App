import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../domain/models/assessment_model.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';

abstract class AssessmentRemoteDataSource {
  Future<AssessmentModel> create({
    required String id,
    required String courseId,
    required String activityId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    required bool gradesVisible,
  });
  Future<AssessmentModel?> getByActivity(String activityId);
  Future<AssessmentModel> update(AssessmentModel a);
  Future<void> deleteByActivity(String activityId);
}

class RobleAssessmentRemoteDataSource implements AssessmentRemoteDataSource {
  final String projectId;
  final http.Client _client;
  final bool debugLogging;

  RobleAssessmentRemoteDataSource({required this.projectId, http.Client? client, this.debugLogging = true})
      : _client = client ?? http.Client();

  String get _base => 'https://roble-api.openlab.uninorte.edu.co/database/$projectId';

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<String?> _readAccessToken() async {
    final auth = Get.isRegistered<AuthLocalDataSource>() ? Get.find<AuthLocalDataSource>() : HiveAuthLocalDataSource();
    if (auth is HiveAuthLocalDataSource) {
      return auth.readAccessToken();
    }
    return null;
  }

  void _logRequest(String method, String url, Map<String, dynamic>? body) {
    if (!debugLogging) return;
    // ignore: avoid_print
    print('[AssessmentsAPI] -> $method $url body=${body == null ? '{}' : jsonEncode(body)}');
  }

  void _logResponse(String method, String url, http.Response resp) {
    if (!debugLogging) return;
    // ignore: avoid_print
    print('[AssessmentsAPI] <- $method $url status=${resp.statusCode} body=${resp.body}');
  }

  AssessmentModel _fromMap(Map<String, dynamic> m) => AssessmentModel(
        id: (m['id'] ?? m['_id'] ?? '') as String,
        courseId: (m['courseId'] ?? '') as String,
        activityId: (m['activityId'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        durationMinutes: (m['durationMinutes'] ?? 0) as int,
        startAt: DateTime.tryParse((m['startAt'] ?? '') as String) ?? DateTime.fromMillisecondsSinceEpoch(0),
        gradesVisible: (m['gradesVisible'] ?? false) as bool,
        cancelled: (m['cancelled'] ?? false) as bool,
      );

  @override
  Future<AssessmentModel?> getByActivity(String activityId) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/read?tableName=AssessmentModel&activityId=${Uri.encodeQueryComponent(activityId)}';
    _logRequest('GET', url, null);
    final resp = await _client.get(Uri.parse(url), headers: _headers(token));
    _logResponse('GET', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
    final data = jsonDecode(resp.body);
    if (data is List && data.isNotEmpty && data.first is Map) {
      return _fromMap(Map<String, dynamic>.from(data.first as Map));
    }
    return null;
  }

  @override
  Future<AssessmentModel> create({
    required String id,
    required String courseId,
    required String activityId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    required bool gradesVisible,
  }) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    // enforce single assessment per activity
    final existing = await getByActivity(activityId);
    if (existing != null) return existing;
    final url = '$_base/insert';
    final record = {
      'id': id,
      'courseId': courseId,
      'activityId': activityId,
      'title': title,
      'durationMinutes': durationMinutes,
      'startAt': startAt.toIso8601String(),
      'gradesVisible': gradesVisible,
      'cancelled': false,
    };
    final body = {
      'tableName': 'AssessmentModel',
      'records': [record],
    };
    _logRequest('POST', url, body);
    final resp = await _client.post(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _logResponse('POST', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to insert assessment: ${resp.statusCode} ${resp.body}');
    }
    try {
      if (resp.body.isNotEmpty) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') || decoded.containsKey('title')) return _fromMap(decoded);
        }
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          final first = Map<String, dynamic>.from(decoded.first as Map);
          if (first.containsKey('id') || first.containsKey('title')) return _fromMap(first);
        }
      }
    } catch (_) {}
    return (await getByActivity(activityId)) ?? _fromMap(record);
  }

  @override
  Future<AssessmentModel> update(AssessmentModel a) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/update';
    final body = {
      'tableName': 'AssessmentModel',
      'idColumn': 'id',
      'idValue': a.id,
      'updates': {
        'title': a.title,
        'durationMinutes': a.durationMinutes,
        'startAt': a.startAt.toIso8601String(),
        'gradesVisible': a.gradesVisible,
        'cancelled': a.cancelled,
      },
    };
    _logRequest('PUT', url, body);
    final resp = await _client.put(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _logResponse('PUT', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to update assessment: ${resp.statusCode} ${resp.body}');
    }
    final refreshed = await getByActivity(a.activityId);
    if (refreshed == null) throw Exception('Updated assessment not found');
    return refreshed;
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    // find by activityId then delete by id
    final existing = await getByActivity(activityId);
    if (existing == null) return;
    final url = '$_base/delete';
    final body = {
      'tableName': 'AssessmentModel',
      'idColumn': 'id',
      'idValue': existing.id,
    };
    _logRequest('DELETE', url, body);
    final resp = await _client.delete(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _logResponse('DELETE', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to delete assessment: ${resp.statusCode} ${resp.body}');
    }
  }
}
