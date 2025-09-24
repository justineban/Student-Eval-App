// Removed unnecessary library name per analyzer suggestion.

// Remote API data source implementation for Roble API.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<RemoteAuthSession?> login(String email, String password);
  Future<RemoteAuthSession?> register(String name, String email, String password);
  Future<RemoteAuthSession?> refreshToken(String refreshToken);
  Future<bool> verifyToken(String accessToken);
}

class RobleAuthRemoteDataSource implements AuthRemoteDataSource {
  final String projectId;
  final http.Client _client;
  final bool debugLogging;
  RobleAuthRemoteDataSource({required this.projectId, http.Client? client, this.debugLogging = true}) : _client = client ?? http.Client();

  String get _base => 'https://roble-api.openlab.uninorte.edu.co/auth/$projectId';

  Map<String, String> get _jsonHeaders => const {'Content-Type': 'application/json'};

  @override
  Future<RemoteAuthSession?> login(String email, String password) async {
    final uri = Uri.parse('$_base/login');
    final body = {'email': email, 'password': password};
    _logRequest('POST', uri.toString(), body);
    final resp = await _client.post(uri, headers: _jsonHeaders, body: jsonEncode(body));
    _logResponse('POST', uri.toString(), resp);
    return _toSessionOrNull(resp);
  }

  @override
  Future<RemoteAuthSession?> register(String name, String email, String password) async {
    final uri = Uri.parse('$_base/signup-direct');
    final body = {'email': email, 'password': password, 'name': name};
    _logRequest('POST', uri.toString(), body);
    final resp = await _client.post(uri, headers: _jsonHeaders, body: jsonEncode(body));
    _logResponse('POST', uri.toString(), resp);
    return _toSessionOrNull(resp);
  }

  @override
  Future<RemoteAuthSession?> refreshToken(String refreshToken) async {
    final uri = Uri.parse('$_base/refresh-token');
    final body = {'refreshToken': refreshToken};
    _logRequest('POST', uri.toString(), body);
    final resp = await _client.post(uri, headers: _jsonHeaders, body: jsonEncode(body));
    _logResponse('POST', uri.toString(), resp);
    return _toSessionOrNull(resp);
  }

  @override
  Future<bool> verifyToken(String accessToken) async {
    final uri = Uri.parse('$_base/verify-token');
    _logRequest('GET', uri.toString(), null, token: accessToken);
    final resp = await _client.get(uri, headers: {
      ..._jsonHeaders,
      'Authorization': 'Bearer $accessToken',
    });
    _logResponse('GET', uri.toString(), resp);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  void _logRequest(String method, String url, Map<String, dynamic>? body, {String? token}) {
    if (!debugLogging) return;
    final redactedBody = body == null
        ? null
        : body.map((k, v) {
            var value = v;
            if (k.toLowerCase().contains('password')) value = '***';
            return MapEntry(k, value);
          });
    final tokenPreview = token == null ? '' : ' (Authorization: Bearer ${_preview(token)})';
    // ignore: avoid_print
    print('[AuthAPI] -> $method $url$tokenPreview body=${redactedBody ?? '{}'}');
  }

  void _logResponse(String method, String url, http.Response resp) {
    if (!debugLogging) return;
    final previewBody = _preview(resp.body);
    // ignore: avoid_print
    print('[AuthAPI] <- $method $url status=${resp.statusCode} body=$previewBody');
  }

  String _preview(String s) {
    const max = 400;
    if (s.length <= max) return s;
    return s.substring(0, max) + '...(${s.length} chars)';
  }

  RemoteAuthSession? _toSessionOrNull(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        if (resp.body.isEmpty) {
          // Some endpoints (e.g. 201 Created) may not return JSON. Treat as success.
          return RemoteAuthSession(accessToken: '', refreshToken: '', user: null);
        }
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          return RemoteAuthSession.fromJson(decoded);
        }
      } catch (_) {
        // If decoding fails but status is 2xx, still return a success session with empty tokens.
        return RemoteAuthSession(accessToken: '', refreshToken: '', user: null);
      }
      // Non-Map but still 2xx: return empty session
      return RemoteAuthSession(accessToken: '', refreshToken: '', user: null);
    }
    // Non-2xx: try to extract a meaningful error message and throw
    String? message;
    try {
      if (resp.body.isNotEmpty) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          final m = decoded['message'];
          if (m is String) {
            message = m;
          } else if (m is List) {
            final parts = m.whereType<String>().toList();
            if (parts.isNotEmpty) message = parts.join('\n');
          }
        } else if (decoded is String) {
          message = decoded;
        }
      }
    } catch (_) {
      // ignore parse errors
    }
    message ??= resp.reasonPhrase ?? 'Error ${resp.statusCode}';
    throw AuthApiException(resp.statusCode, message);
  }
}

class AuthApiException implements Exception {
  final int statusCode;
  final String message;
  AuthApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

/// Represents the remote auth response containing tokens and user basic info.
class RemoteAuthSession {
  final String accessToken;
  final String refreshToken;
  final UserModel? user;

  RemoteAuthSession({required this.accessToken, required this.refreshToken, required this.user});

  factory RemoteAuthSession.fromJson(Map<String, dynamic> json) {
    // Flexible mapping: supports variants like { token, refreshToken, user }
    // or { accessToken, refreshToken, profile } etc.
    final access = (json['accessToken'] ?? json['token'] ?? json['jwt']) as String? ?? '';
    final refresh = (json['refreshToken'] ?? json['refresh']) as String? ?? '';
    final dynamic u = json['user'] ?? json['profile'] ?? json['account'];
    UserModel? user;
    if (u is Map) {
      final userMap = Map<String, dynamic>.from(u);
      final id = (userMap['id'] ?? userMap['_id'] ?? userMap['uid'] ?? userMap['userId']) as String? ?? '';
      final email = (userMap['email'] ?? userMap['mail']) as String? ?? '';
      final name = (userMap['name'] ?? userMap['fullName'] ?? userMap['displayName']) as String? ?? '';
      user = UserModel(id: id, email: email, password: '', name: name);
    }
    return RemoteAuthSession(accessToken: access, refreshToken: refresh, user: user);
  }
}
