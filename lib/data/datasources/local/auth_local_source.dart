class AuthLocalSource {
  final List<Map<String, dynamic>> _users = [];

  Future<Map<String, dynamic>?> getUserByCredentials(
    String email,
    String password,
  ) async {
    try {
      return _users.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveUser(Map<String, dynamic> userData) async {
    _users.add(userData);
    return true;
  }
}
