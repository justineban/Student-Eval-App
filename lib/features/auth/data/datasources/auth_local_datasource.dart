library auth_local_datasource;

/// Local (Hive/SQL) data source stub for authentication.
/// In-memory + Hive implementations.
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> fetchUserByEmail(String email);
  Future<UserModel> saveUser(UserModel user);
  Future<void> persistSessionUserId(String userId);
  Future<String?> readSessionUserId();
  Future<void> clearSession();
}

class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  final Map<String, UserModel> _users = {}; // key email
  String? _sessionUserId;

  @override
  Future<UserModel?> fetchUserByEmail(String email) async => _users[email];

  @override
  Future<UserModel> saveUser(UserModel user) async {
    _users[user.email] = user;
    return user;
  }

  @override
  Future<void> persistSessionUserId(String userId) async {
    _sessionUserId = userId;
  }

  @override
  Future<String?> readSessionUserId() async => _sessionUserId;

  @override
  Future<void> clearSession() async {
    _sessionUserId = null;
  }
}

/// Hive-backed implementation
class HiveAuthLocalDataSource implements AuthLocalDataSource {
  late final Box _usersBox;
  late final Box _sessionBox;

  HiveAuthLocalDataSource({Box? usersBox, Box? sessionBox}) {
    _usersBox = usersBox ?? Hive.box(HiveBoxes.users);
    _sessionBox = sessionBox ?? Hive.box(HiveBoxes.session);
  }

  static const _sessionKey = 'currentUserId';

  @override
  Future<UserModel?> fetchUserByEmail(String email) async {
    // Iterate keys (acceptable for small local user set). Optimize later with index if needed.
    for (final key in _usersBox.keys) {
      final data = _usersBox.get(key);
      if (data is Map && data['email'] == email) {
        return _mapToUser(data);
      }
    }
    return null;
  }

  @override
  Future<UserModel> saveUser(UserModel user) async {
    await _usersBox.put(user.id, _userToMap(user));
    return user;
  }

  @override
  Future<void> persistSessionUserId(String userId) async {
    await _sessionBox.put(_sessionKey, userId);
  }

  @override
  Future<String?> readSessionUserId() async {
    return _sessionBox.get(_sessionKey) as String?;
  }

  @override
  Future<void> clearSession() async {
    await _sessionBox.delete(_sessionKey);
  }

  Map<String, dynamic> _userToMap(UserModel u) => {
        'id': u.id,
        'name': u.name,
        'email': u.email,
        'password': u.password,
      };

  UserModel _mapToUser(Map map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
      );
}
