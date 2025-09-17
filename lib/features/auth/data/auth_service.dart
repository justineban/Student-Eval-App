import 'package:flutter/material.dart';

import '../../../core/entities/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();


  User? _currentUser;
  final List<User> _users = [];

  User? get currentUser => _currentUser;
  set currentUser(User? user) => _currentUser = user;
  List<User> get users => _users;

  Future<bool> login(String email, String password) async {
    try {
      final user = _users.firstWhere(
        (user) => user.email == email && user.password == password,
      );
      _currentUser = user;
      return true;
    } catch (e) {
      throw Exception('Usuario o contraseña incorrectos');
    }
  }

  Future<bool> register(String email, String password, String name) async {
    if (_users.any((user) => user.email == email)) {
      throw Exception('El email ya está registrado');
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      password: password,
      name: name,
    );

    _users.add(user);
    debugPrint('Usuario registrado: $email');
    return true;
  }

  void logout() {
    _currentUser = null;
  }
}
