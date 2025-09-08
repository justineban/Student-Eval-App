import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final List<User> _users = [];

  User? get currentUser => _currentUser;
  // Expose a read-only view of registered users so UI screens can list them
  List<User> get users => List.unmodifiable(_users);

  // Current role for the active session. Can be changed without logging out.
  String? _currentRole;
  String? get currentRole => _currentRole;
  void setRole(String? role) {
    _currentRole = role;
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = _users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
      _currentUser = user;
      return true;
    } catch (e) {
      throw Exception('Usuario o contraseña incorrectos');
    }
  }

  Future<bool> register(String email, String password, String name) async {
    if (_users.any((user) => user.email == email)) {
      throw Exception('El email ya está registrado');
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      password: password,
      name: name,
    );

    _users.add(user);
    return true;
  }

  void logout() {
    _currentUser = null;
  }
}
