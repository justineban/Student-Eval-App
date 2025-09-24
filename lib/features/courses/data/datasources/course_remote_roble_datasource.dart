import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../domain/models/course_model.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import 'course_local_datasource.dart';

/// Remote datasource implementation using Roble Database API for CourseModel table.
class RobleCourseRemoteDataSource implements CourseRemoteDataSource {
	final String projectId;
	final http.Client _client;
	final bool debugLogging;

	RobleCourseRemoteDataSource({required this.projectId, http.Client? client, this.debugLogging = true})
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
		print('[CoursesAPI] -> $method $url body=${body == null ? '{}' : jsonEncode(body)}');
	}

	void _logResponse(String method, String url, http.Response resp) {
		if (!debugLogging) return;
		// ignore: avoid_print
			print('[CoursesAPI] <- $method $url status=${resp.statusCode} body=${resp.body}');
	}

		CourseModel _fromMap(Map<String, dynamic> m) => CourseModel(
					id: (m['id'] ?? m['_id'] ?? '') as String,
					name: (m['name'] ?? '') as String,
					description: (m['description'] ?? '') as String,
					teacherId: (m['teacherId'] ?? '') as String,
					registrationCode: (m['registrationCode'] ?? '') as String,
					studentIds: _asStringList(m['studentIds']),
					invitations: _asStringList(m['invitations']),
				);

		List<String> _asStringList(dynamic value) {
			if (value is List) {
				return value.map((e) => e.toString()).toList();
			}
			if (value is Map) {
				// In case backend returns an object map, take stringified values
				return value.values.map((e) => e.toString()).toList();
			}
			return <String>[];
		}

	@override
	Future<CourseModel> createRemoteCourse({required String name, required String description, required String teacherId}) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) {
			throw Exception('No access token available');
		}
		final url = '$_base/insert';
		final record = {
			// Use 'id' column as requested; do not send '_id'
			'id': _generateId(),
			'name': name,
			'description': description,
			'teacherId': teacherId,
			'registrationCode': _generateRegistrationCode(),
			'studentIds': <String>[],
			'invitations': <String>[],
		};
		final body = {
			'tableName': 'CourseModel',
			'records': [record],
		};
		_logRequest('POST', url, body);
		final resp = await _client.post(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
		_logResponse('POST', url, resp);
			if (resp.statusCode < 200 || resp.statusCode >= 300) {
				throw Exception('Failed to insert course: ${resp.statusCode} ${resp.body}');
			}
			// Try to parse response body as created record(s)
			try {
				if (resp.body.isNotEmpty) {
					final decoded = jsonDecode(resp.body);
					if (decoded is Map<String, dynamic>) {
						// If API returns the created object directly
						return _fromMap(decoded);
					}
					if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
						return _fromMap(Map<String, dynamic>.from(decoded.first as Map));
					}
				}
			} catch (_) {
				// ignore parse errors and fallback to read-by-id
			}
			// After insert, try to read back by id to return the stored record
			final createdId = record['id'] as String;
			final fetched = await _readById(token, createdId);
			return fetched ?? _fromMap(record);
	}

	@override
	Future<List<CourseModel>> fetchRemoteCoursesByTeacher(String teacherId) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) {
			throw Exception('No access token available');
		}
		final url = '$_base/read?tableName=CourseModel&teacherId=${Uri.encodeQueryComponent(teacherId)}';
		_logRequest('GET', url, null);
		final resp = await _client.get(Uri.parse(url), headers: _headers(token));
		_logResponse('GET', url, resp);
		if (resp.statusCode < 200 || resp.statusCode >= 300) {
			throw Exception('Failed to fetch courses: ${resp.statusCode} ${resp.body}');
		}
			final data = jsonDecode(resp.body);
			if (data is List) {
				return data
						.whereType<Map>()
						.map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
						.toList();
			}
			if (data is Map<String, dynamic>) {
				// Try common wrappers like {items:[...]}, {data:[...]}
				final list = (data['items'] ?? data['data']) as List?;
				if (list != null) {
					return list
						.whereType<Map>()
						.map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
						.toList();
				}
			}
		return <CourseModel>[];
	}

	Future<CourseModel?> _readById(String token, String id) async {
		final url = '$_base/read?tableName=CourseModel&id=${Uri.encodeQueryComponent(id)}';
		_logRequest('GET', url, null);
		final resp = await _client.get(Uri.parse(url), headers: _headers(token));
		_logResponse('GET', url, resp);
		if (resp.statusCode < 200 || resp.statusCode >= 300) {
			return null;
		}
		final data = jsonDecode(resp.body);
		if (data is List && data.isNotEmpty && data.first is Map) {
			return _fromMap(Map<String, dynamic>.from(data.first as Map));
		}
		return null;
	}

	@override
	Future<CourseModel?> fetchRemoteCourseById(String id) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) throw Exception('No access token available');
		return _readById(token, id);
	}

	@override
	Future<CourseModel> updateRemoteCourse({required String id, required Map<String, dynamic> updates}) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) throw Exception('No access token available');
		final url = '$_base/update';
		// Ensure we never try to update immutable id column name
		final sanitized = Map<String, dynamic>.from(updates)
			..remove('_id')
			..remove('id');
		final body = {
			'tableName': 'CourseModel',
			'idColumn': 'id',
			'idValue': id,
			'updates': sanitized,
		};
		_logRequest('PUT', url, body);
		final resp = await _client.put(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
		_logResponse('PUT', url, resp);
		if (resp.statusCode < 200 || resp.statusCode >= 300) {
			throw Exception('Failed to update course: ${resp.statusCode} ${resp.body}');
		}
		// Return updated course
		final updated = await fetchRemoteCourseById(id);
		if (updated == null) throw Exception('Updated course not found');
		return updated;
	}

	@override
	Future<void> deleteRemoteCourse(String id) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) throw Exception('No access token available');
		final url = '$_base/delete';
		final body = {
			'tableName': 'CourseModel',
			'idColumn': 'id',
			'idValue': id,
		};
		_logRequest('DELETE', url, body);
		final resp = await _client.delete(Uri.parse(url), headers: _headers(token), body: jsonEncode(body));
		_logResponse('DELETE', url, resp);
		if (resp.statusCode < 200 || resp.statusCode >= 300) {
			throw Exception('Failed to delete course: ${resp.statusCode} ${resp.body}');
		}
	}

	@override
	Future<CourseModel?> fetchRemoteCourseByRegistrationCode(String code) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) throw Exception('No access token available');
		final url = '$_base/read?tableName=CourseModel&registrationCode=${Uri.encodeQueryComponent(code)}';
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
	Future<List<CourseModel>> fetchRemoteCoursesByStudent(String studentId) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) throw Exception('No access token available');
		// Backend no admite filtro directo sobre JSON arrays; traemos todos y filtramos por studentIds
		final url = '$_base/read?tableName=CourseModel';
		_logRequest('GET', url, null);
		final resp = await _client.get(Uri.parse(url), headers: _headers(token));
		_logResponse('GET', url, resp);
		if (resp.statusCode < 200 || resp.statusCode >= 300) return <CourseModel>[];
		final data = jsonDecode(resp.body);
		List<CourseModel> all = <CourseModel>[];
		if (data is List) {
			all = data
					.whereType<Map>()
					.map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
					.toList();
		} else if (data is Map<String, dynamic>) {
			final list = (data['items'] ?? data['data']) as List?;
			if (list != null) {
				all = list
						.whereType<Map>()
						.map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
						.toList();
			}
		}
		return all.where((c) => c.studentIds.contains(studentId)).toList();
	}

	@override
	Future<List<CourseModel>> fetchRemoteInvitedCoursesForEmail(String email) async {
		final token = await _readAccessToken();
		if (token == null || token.isEmpty) throw Exception('No access token available');
		final lower = email.toLowerCase();
		// Backend no admite filtros JSON por query; traer todos y filtrar en cliente
		final url = '$_base/read?tableName=CourseModel';
		_logRequest('GET', url, null);
		final resp = await _client.get(Uri.parse(url), headers: _headers(token));
		_logResponse('GET', url, resp);
		if (resp.statusCode < 200 || resp.statusCode >= 300) return <CourseModel>[];
		final data = jsonDecode(resp.body);
		List<CourseModel> all = <CourseModel>[];
		if (data is List) {
			all = data
					.whereType<Map>()
					.map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
					.toList();
		} else if (data is Map<String, dynamic>) {
			final list = (data['items'] ?? data['data']) as List?;
			if (list != null) {
				all = list
						.whereType<Map>()
						.map((e) => _fromMap(e.map((k, v) => MapEntry(k.toString(), v))))
						.toList();
			}
		}
		// Filtrar por invitaciones que contengan el email (normalizado en minúsculas)
		return all.where((c) => c.invitations.map((e) => e.toLowerCase()).contains(lower)).toList();
	}

	String _generateId() {
		// Simple unique id using timestamp; you can replace with uuid if desired
		return 'course_${DateTime.now().microsecondsSinceEpoch}';
	}

	String _generateRegistrationCode() {
		final millis = DateTime.now().millisecondsSinceEpoch.toString();
		return millis.substring(millis.length - 6);
	}
}
