import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../../core/entities/user.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.login(email, password);
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.register(email, password, name);
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _authService.logout();
    notifyListeners();
  }
}
