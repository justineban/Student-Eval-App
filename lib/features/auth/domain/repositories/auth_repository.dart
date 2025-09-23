library auth_repository_interface;

/// Auth repository abstraction for the auth feature module.
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login({required String email, required String password});
  Future<UserModel?> register({required String name, required String email, required String password});
  Future<void> logout();
  UserModel? get currentUser;
  Future<UserModel?> restoreSession();
}
