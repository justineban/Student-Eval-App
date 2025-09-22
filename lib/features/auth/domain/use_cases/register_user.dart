import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repo;
  RegisterUser(this.repo);

  Future<String?> call({required String email, required String password, required String name}) =>
      repo.register(email: email, password: password, name: name);
}
