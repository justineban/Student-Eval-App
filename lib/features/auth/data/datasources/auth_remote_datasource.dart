// Removed unnecessary library name per analyzer suggestion.

// Remote API data source placeholder (not implemented).
// Future implementation should perform HTTP calls.
import '../../domain/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register(String name, String email, String password);
}

class StubAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel?> login(String email, String password) async => null; // not implemented

  @override
  Future<UserModel?> register(String name, String email, String password) async => null; // not implemented
}
