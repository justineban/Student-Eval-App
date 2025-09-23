import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Repository implementation choosing local first (in-memory) and stubbing remote.
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource local;
  final AuthRemoteDataSource remote; // reserved for future use

  UserModel? _cached;

  AuthRepositoryImpl({required this.local, required this.remote});

  @override
  UserModel? get currentUser => _cached;

  @override
  Future<UserModel?> login({required String email, required String password}) async {
    // Try local
    final localUser = await local.fetchUserByEmail(email);
    if (localUser != null && localUser.password == password) {
      _cached = localUser;
      await local.persistSessionUserId(localUser.id);
      return localUser;
    }
    // Remote (stub) -> not implemented
    final remoteUser = await remote.login(email, password);
    if (remoteUser != null) {
      _cached = remoteUser;
      await local.saveUser(remoteUser);
      await local.persistSessionUserId(remoteUser.id);
    }
    return remoteUser; // null if not found
  }

  /// Attempt to restore a previously persisted session user.
  @override
  Future<UserModel?> restoreSession() async {
    if (_cached != null) return _cached;
    final storedId = await local.readSessionUserId();
    if (storedId == null) return null;
    final user = await local.fetchUserById(storedId);
    _cached = user;
    return user;
  }

  @override
  Future<UserModel?> register({required String name, required String email, required String password}) async {
    final existing = await local.fetchUserByEmail(email);
    if (existing != null) return null; // email taken
    final newUser = UserModel(id: DateTime.now().microsecondsSinceEpoch.toString(), email: email, password: password, name: name);
    await local.saveUser(newUser);
    _cached = newUser;
    await local.persistSessionUserId(newUser.id);
    // Remote register stub ignored
    return newUser;
  }

  @override
  Future<void> logout() async {
    _cached = null;
    await local.clearSession();
  }
}
