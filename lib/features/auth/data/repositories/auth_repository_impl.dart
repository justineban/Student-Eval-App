import 'package:proyecto_movil/core/entities/user.dart' as legacy;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../datasources/local/hive_auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final HiveAuthLocalDataSource local;
  AuthRepositoryImpl(this.local);

  @override
  Future<String?> register({required String email, required String password, required String name}) async {
    if (local.emailExists(email)) {
      throw Exception('Email ya registrado');
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = legacy.User(id: id, email: email, password: password, name: name);
    await local.putUser(id, user);
    local.persistCurrentUserId(id);
    return id;
  }

  @override
  Future<String?> login({required String email, required String password}) async {
    legacy.User? user;
    try {
      user = local.getAllUsers().whereType<legacy.User>().firstWhere(
        (u) => u.email == email && u.password == password,
      );
    } catch (_) {
      user = null;
    }
    if (user == null) throw Exception('Credenciales inválidas');
    local.persistCurrentUserId(user.id);
    return user.id;
  }

  @override
  Future<void> logout() async => local.clearSession();

  @override
  String? getCurrentUserId() => local.loadCurrentUserId();

  AuthUser? getCurrentUser() {
    final id = getCurrentUserId();
    if (id == null) return null;
    final u = local.getUser(id) as legacy.User?;
    if (u == null) return null;
    return AuthUser(id: u.id, email: u.email, name: u.name);
  }
}
