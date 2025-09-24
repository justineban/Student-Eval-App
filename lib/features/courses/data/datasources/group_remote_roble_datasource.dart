import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../domain/models/group_model.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';

abstract class CourseGroupRemoteDataSource {
  Future<GroupModel> createGroup({required String id, required String courseId, required String categoryId, required String name});
  Future<List<GroupModel>> listByCategory(String categoryId);
  Future<GroupModel?> fetchById(String id);
  Future<GroupModel> updateGroup({required String id, required Map<String, dynamic> updates});
  Future<void> deleteGroup(String id);
}

class RobleCourseGroupRemoteDataSource implements CourseGroupRemoteDataSource {
  final String projectId;
  final http.Client _client;
  final bool debugLogging;

  RobleCourseGroupRemoteDataSource({required this.projectId, http.Client? client, this.debugLogging = true})
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
    print('[GroupsAPI] -> $method $url body=${body == null ? '{}' : jsonEncode(body)}');
  }

  void _logResponse(String method, String url, http.Response resp) {
    if (!debugLogging) return;
    // ignore: avoid_print
    print('[GroupsAPI] <- $method $url status=${resp.statusCode} body=${resp.body}');
  }

  GroupModel _fromMap(Map<String, dynamic> m) => GroupModel(
        id: (m['id'] ?? m['_id'] ?? '') as String,
        courseId: (m['courseId'] ?? '') as String,
        categoryId: (m['categoryId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        memberIds: (m['memberIds'] is List)
            ? (m['memberIds'] as List).map((e) => e.toString()).toList()
            : <String>[],
      );

  @override
  Future<GroupModel> createGroup({required String id, required String courseId, required String categoryId, required String name}) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/insert';
    final record = {
      'id': id,
      'courseId': courseId,
      'categoryId': categoryId,
      'name': name,
      'memberIds': <String>[],
    };
    final body = {
      'tableName': 'GroupModel',
      'records': [record],
    };
    _logRequest('POST', url, body);
    final resp = await _client.post(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _logResponse('POST', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to insert group: ${resp.statusCode} ${resp.body}');
    }
    try {
      if (resp.body.isNotEmpty) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('id') || decoded.containsKey('name')) {
            return _fromMap(decoded);
          }
        }
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          final first = Map<String, dynamic>.from(decoded.first as Map);
          if (first.containsKey('id') || first.containsKey('name')) {
            return _fromMap(first);
          }
        }
      }
    } catch (_) {}
    return (await fetchById(id)) ?? _fromMap(record.map((k, v) => MapEntry(k, v)));
  }

  @override
  Future<List<GroupModel>> listByCategory(String categoryId) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/read?tableName=GroupModel&categoryId=${Uri.encodeQueryComponent(categoryId)}';
    _logRequest('GET', url, null);
    final resp = await _client.get(Uri.parse(url), headers: _headers(token));
    _logResponse('GET', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) return <GroupModel>[];
    final data = jsonDecode(resp.body);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = (data['items'] ?? data['data']) as List?;
      if (list != null) {
        return list
            .whereType<Map>()
            .map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
            .toList();
      }
    }
    return <GroupModel>[];
  }

  @override
  Future<GroupModel?> fetchById(String id) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/read?tableName=GroupModel&id=${Uri.encodeQueryComponent(id)}';
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
  Future<GroupModel> updateGroup({required String id, required Map<String, dynamic> updates}) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/update';
    final sanitized = Map<String, dynamic>.from(updates)..remove('_id')..remove('id');
    final body = {
      'tableName': 'GroupModel',
      'idColumn': 'id',
      'idValue': id,
      'updates': sanitized,
    };
    _logRequest('PUT', url, body);
    final resp = await _client.put(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _logResponse('PUT', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to update group: ${resp.statusCode} ${resp.body}');
    }
    final updated = await fetchById(id);
    if (updated == null) throw Exception('Updated group not found');
    return updated;
  }

  @override
  Future<void> deleteGroup(String id) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/delete';
    final body = {
      'tableName': 'GroupModel',
      'idColumn': 'id',
      'idValue': id,
    };
    _logRequest('DELETE', url, body);
    final resp = await _client.delete(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _logResponse('DELETE', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to delete group: ${resp.statusCode} ${resp.body}');
    }
  }
}
