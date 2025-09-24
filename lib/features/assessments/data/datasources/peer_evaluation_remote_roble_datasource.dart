import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../domain/models/peer_evaluation_model.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';

abstract class PeerEvaluationRemoteDataSource {
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluator(String assessmentId, String evaluatorId);
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluatee(String assessmentId, String evaluateeId);
  Future<void> saveAll(List<PeerEvaluationModel> list);
}

class RoblePeerEvaluationRemoteDataSource implements PeerEvaluationRemoteDataSource {
  final String projectId;
  final http.Client _client;
  final bool debugLogging;

  RoblePeerEvaluationRemoteDataSource({required this.projectId, http.Client? client, this.debugLogging = true})
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
    print('[PeerEvalAPI] -> $method $url body=${body == null ? '{}' : jsonEncode(body)}');
  }

  void _logResponse(String method, String url, http.Response resp) {
    if (!debugLogging) return;
    // ignore: avoid_print
    print('[PeerEvalAPI] <- $method $url status=${resp.statusCode} body=${resp.body}');
  }

  PeerEvaluationModel _fromMap(Map<String, dynamic> m) => PeerEvaluationModel(
        id: (m['id'] ?? m['_id'] ?? '') as String,
        assessmentId: (m['assessmentId'] ?? '') as String,
        evaluatorId: (m['evaluatorId'] ?? '') as String,
        evaluateeId: (m['evaluateeId'] ?? '') as String,
        punctuality: (m['punctuality'] ?? 0) as int,
        contributions: (m['contributions'] ?? 0) as int,
        commitment: (m['commitment'] ?? 0) as int,
        attitude: (m['attitude'] ?? 0) as int,
      );

  @override
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluator(String assessmentId, String evaluatorId) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/read?tableName=PeerEvaluationModel&assessmentId=${Uri.encodeQueryComponent(assessmentId)}&evaluatorId=${Uri.encodeQueryComponent(evaluatorId)}';
    _logRequest('GET', url, null);
    final resp = await _client.get(Uri.parse(url), headers: _headers(token));
    _logResponse('GET', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) return <PeerEvaluationModel>[];
    final data = jsonDecode(resp.body);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    }
    return <PeerEvaluationModel>[];
  }

  @override
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluatee(String assessmentId, String evaluateeId) async {
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    final url = '$_base/read?tableName=PeerEvaluationModel&assessmentId=${Uri.encodeQueryComponent(assessmentId)}&evaluateeId=${Uri.encodeQueryComponent(evaluateeId)}';
    _logRequest('GET', url, null);
    final resp = await _client.get(Uri.parse(url), headers: _headers(token));
    _logResponse('GET', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) return <PeerEvaluationModel>[];
    final data = jsonDecode(resp.body);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    }
    return <PeerEvaluationModel>[];
  }

  @override
  Future<void> saveAll(List<PeerEvaluationModel> list) async {
    if (list.isEmpty) return;
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) throw Exception('No access token available');
    // Strategy: delete existing for the same (assessmentId, evaluatorId) then insert the new list
    final assessmentId = list.first.assessmentId;
    final evaluatorId = list.first.evaluatorId;
    final existing = await getByAssessmentAndEvaluator(assessmentId, evaluatorId);
    for (final ev in existing) {
      final urlDel = '$_base/delete';
      final bodyDel = {
        'tableName': 'PeerEvaluationModel',
        'idColumn': 'id',
        'idValue': ev.id,
      };
      _logRequest('DELETE', urlDel, bodyDel);
      final respDel = await _client.delete(Uri.parse(urlDel), headers: _headers(token), body: jsonEncode(bodyDel));
      _logResponse('DELETE', urlDel, respDel);
    }

    final url = '$_base/insert';
    final records = list
        .map((e) => {
              'id': e.id,
              'assessmentId': e.assessmentId,
              'evaluatorId': e.evaluatorId,
              'evaluateeId': e.evaluateeId,
              'punctuality': e.punctuality,
              'contributions': e.contributions,
              'commitment': e.commitment,
              'attitude': e.attitude,
            })
        .toList();
    final body = {
      'tableName': 'PeerEvaluationModel',
      'records': records,
    };
    _logRequest('POST', url, body);
    final resp = await _client.post(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
    _logResponse('POST', url, resp);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to save peer evaluations: ${resp.statusCode} ${resp.body}');
    }
  }
}
