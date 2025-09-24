import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Repository implementation choosing local first (in-memory) and stubbing remote.
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource local;
  final AuthRemoteDataSource remote;

  UserModel? _cached;

  AuthRepositoryImpl({required this.local, required this.remote});

  @override
  UserModel? get currentUser => _cached;

  @override
  Future<UserModel?> login({required String email, required String password}) async {
    // Always prefer remote login to obtain tokens
    final session = await remote.login(email, password);
    if (session == null) return null; // non-2xx handled as exception further up if thrown
  // Some endpoints may return only tokens. Prefer the provided user when present; otherwise, keep existing or create placeholder.
  final effectiveUser = await _ensureUserFromSession(session, fallbackEmail: email);
  _cached = effectiveUser;
  await local.saveUser(effectiveUser);
  await local.persistSessionUserId(effectiveUser.id);
    // Optionally persist tokens in session store for refresh; use dedicated keys if supported by local datasource
    if (local is HiveAuthLocalDataSource) {
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      final hive = (local as HiveAuthLocalDataSource);
      // Use dynamic keys to avoid API surface change; store under well-known keys
      await hive.persistTokenPair(session.accessToken, session.refreshToken);
    }
    return session.user;
  }

  /// Attempt to restore a previously persisted session user.
  @override
  Future<UserModel?> restoreSession() async {
    if (_cached != null) return _cached;
    final storedId = await local.readSessionUserId();
    if (storedId != null) {
      final user = await local.fetchUserById(storedId);
      if (user != null) {
        _cached = user;
        return user;
      }
    }
    // Try refresh-token flow if available
    if (local is HiveAuthLocalDataSource) {
      final hive = (local as HiveAuthLocalDataSource);
      final refresh = hive.readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        final session = await remote.refreshToken(refresh);
        if (session != null) {
          final effectiveUser = await _ensureUserFromSession(session);
          _cached = effectiveUser;
          await local.saveUser(effectiveUser);
          await local.persistSessionUserId(effectiveUser.id);
          await hive.persistTokenPair(session.accessToken, session.refreshToken);
          return effectiveUser;
        }
      }
    }
    return null;
  }

  @override
  Future<UserModel?> register({required String name, required String email, required String password}) async {
  final session = await remote.register(name, email, password);
    if (session == null) return null; // non-2xx
  // For 201 con mensaje (sin tokens/usuario), _ensureUserFromSession creará usuario local con nombre/email
  final effectiveUser = await _ensureUserFromSession(session, fallbackEmail: email, fallbackName: name);
  _cached = effectiveUser;
  await local.saveUser(effectiveUser);
  await local.persistSessionUserId(effectiveUser.id);
    if (local is HiveAuthLocalDataSource) {
      final hive = (local as HiveAuthLocalDataSource);
      await hive.persistTokenPair(session.accessToken, session.refreshToken);
    }
    return session.user;
  }

  @override
  Future<void> logout() async {
    _cached = null;
    await local.clearSession();
  }
}

extension on AuthRepositoryImpl {
  Future<UserModel> _ensureUserFromSession(RemoteAuthSession session, {String? fallbackEmail, String? fallbackName}) async {
    // If the session carries a user, use it directly.
    if (session.user != null) return session.user!;

    // Try to reuse existing session user id if present
    final storedId = await local.readSessionUserId();
    if (storedId != null) {
      final u = await local.fetchUserById(storedId);
      if (u != null) return u;
    }

    // As last resort, create a placeholder user so the app can proceed. Use fallback email/name if provided.
    final email = fallbackEmail ?? '';
    final name = fallbackName ?? (email.isNotEmpty ? email.split('@').first : '');
    // Generate a stable id based on email or timestamp
    final id = email.isNotEmpty ? email : DateTime.now().millisecondsSinceEpoch.toString();
    return UserModel(id: id, email: email, password: '', name: name);
  }
}
