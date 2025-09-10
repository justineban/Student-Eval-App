import '../../domain/models/user.dart';

abstract class AuthRepository {
  User? get currentUser;
  List<User> get users;
  String? get currentRole;

  void setRole(String? role);
  Future<bool> login(String email, String password);
  Future<bool> register(String email, String password, String name);
  void logout();
}
