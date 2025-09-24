import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<UserModel?> call(String email, String password) async {
    return repository.login(email: email.trim(), password: password);
  }
}
