import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'auth_local_datasource.dart';

abstract class UserRemoteDataSource {
  Future<String?> fetchNameByUserId(String userId);
  Future<void> insertUser({required String userId, required String name});
}

class RobleUserRemoteDataSource implements UserRemoteDataSource {
  final String projectId;
  final http.Client _client;
  final bool debugLogging;

  RobleUserRemoteDataSource({required this.projectId, http.Client? client, this.debugLogging = true})
      : _client = client ?? http.Client();

  String get _base => 'https://roble-api.openlab.uninorte.edu.co/database/$projectId';

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<String?> _readAccessToken() async {
    final auth = Get.isRegistered<AuthLocalDataSource>() ? Get.find<AuthLocalDataSource>() : HiveAuthLocalDataSource();
    if (auth is HiveAuthLocalDataSource) return auth.readAccessToken();
    return null;
  }

  void _log(String tag, String msg) {
    if (!debugLogging) return;
    // ignore: avoid_print
    print('[UserAPI] $tag $msg');
  }

  @override
  Future<String?> fetchNameByUserId(String userId) async {
    // Log every name request
    // ignore: avoid_print
    print('[NameRequest] Remote.fetchNameByUserId: $userId');
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) {
      // fallback to local if available
      try {
        final local = Get.isRegistered<AuthLocalDataSource>() ? Get.find<AuthLocalDataSource>() : null;
        if (local != null) {
          final u = await local.fetchUserById(userId);
          return u?.name;
        }
      } catch (_) {}
      return null;
    }
    final url = '$_base/read?tableName=UserModel&userId=${Uri.encodeQueryComponent(userId)}';
    _log('GET', url);
    try {
      final resp = await _client.get(Uri.parse(url), headers: _headers(token));
      _log('RESP', '${resp.statusCode} ${resp.body}');
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return null;
      }
      final data = jsonDecode(resp.body);
      if (data is List && data.isNotEmpty && data.first is Map) {
        final m = Map<String, dynamic>.from(data.first as Map);
        return (m['name'] ?? '') as String?;
      }
      if (data is Map) {
        final list = (data['items'] ?? data['data']) as List?;
        if (list != null && list.isNotEmpty && list.first is Map) {
          final m = Map<String, dynamic>.from(list.first as Map);
          return (m['name'] ?? '') as String?;
        }
      }
    } catch (e) {
      _log('ERR', e.toString());
    }
    // fallback to local if remote failed
    try {
      final local = Get.isRegistered<AuthLocalDataSource>() ? Get.find<AuthLocalDataSource>() : null;
      if (local != null) {
        final u = await local.fetchUserById(userId);
        return u?.name;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> insertUser({required String userId, required String name}) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) {
      _log('SKIP', 'No token available to insert user row');
      return;
    }
    final url = '$_base/insert';
    final record = {
      'userId': userId,
      'name': name,
    };
    final body = {
      'tableName': 'UserModel',
      'records': [record],
    };
    _log('POST', url);
    final resp = await _client.post(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _log('RESP', '${resp.statusCode} ${resp.body}');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to insert UserModel row: ${resp.statusCode} ${resp.body}');
    }
  }
}
