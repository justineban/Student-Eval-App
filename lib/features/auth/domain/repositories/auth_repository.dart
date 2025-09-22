abstract class AuthRepository {
  Future<String?> register({required String email, required String password, required String name});
  Future<String?> login({required String email, required String password});
  Future<void> logout();
  String? getCurrentUserId();
}
