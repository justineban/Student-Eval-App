import 'package:proyecto_movil/features/auth/domain/entities/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final List<User> _users = [];

  User? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    try {
      final user = _users.firstWhere((u) => u.email == email && u.password == password);
      _currentUser = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    if (_users.any((u) => u.email == email)) return false;
    final user = User(id: DateTime.now().millisecondsSinceEpoch.toString(), email: email, password: password, name: name);
    _users.add(user);
    _currentUser = user;
    return true;
  }

  void logout() {
    _currentUser = null;
  }
}
