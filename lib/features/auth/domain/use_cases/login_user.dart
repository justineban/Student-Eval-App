import '../repositories/auth_repository.dart';

class LoginUser {
  final AuthRepository repo;
  LoginUser(this.repo);

  Future<String?> call({required String email, required String password}) =>
      repo.login(email: email, password: password);
}
