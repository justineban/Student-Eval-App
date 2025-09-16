import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';

class AuthController extends ChangeNotifier {
  final LocalRepository repo;
  AuthController(this.repo);

  User? login(String email, String password) => repo.login(email, password);

  Future<User?> register(String email, String password, String name) => repo.register(email, password, name);

  Future<void> logout() => repo.logout();
}
