import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<UserModel?> call({required String name, required String email, required String password}) async {
    return repository.register(name: name.trim(), email: email.trim(), password: password);
  }
}
