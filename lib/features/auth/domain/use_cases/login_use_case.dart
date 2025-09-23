import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<UserModel?> call(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) return null;
    return repository.login(email: email.trim(), password: password);
  }
}
