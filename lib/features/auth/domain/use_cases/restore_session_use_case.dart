import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

class RestoreSessionUseCase {
  final AuthRepository repository;
  RestoreSessionUseCase(this.repository);

  Future<UserModel?> call() => repository.restoreSession();
}
