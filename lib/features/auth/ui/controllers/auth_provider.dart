import 'package:flutter/widgets.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/register_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import 'auth_controller.dart';

/// Simple manual dependency assembly for the Auth feature.
/// Later you can replace this with get_it, riverpod, etc.
class AuthProvider extends InheritedWidget {
  final AuthController controller;

  AuthProvider._({required this.controller, required super.child});

  factory AuthProvider({required Widget child}) {
    // Build data layer
    final local = InMemoryAuthLocalDataSource();
    final remote = StubAuthRemoteDataSource();
    final repo = AuthRepositoryImpl(local: local, remote: remote);

    // Build use cases
    final loginUC = LoginUseCase(repo);
    final registerUC = RegisterUseCase(repo);
    final logoutUC = LogoutUseCase(repo);

    // Controller
    final controller = AuthController(
      loginUseCase: loginUC,
      registerUseCase: registerUC,
      logoutUseCase: logoutUC,
    );

    return AuthProvider._(controller: controller, child: child);
  }

  static AuthController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AuthProvider>();
    assert(provider != null, 'AuthProvider not found in context');
    return provider!.controller;
  }

  @override
  bool updateShouldNotify(covariant AuthProvider oldWidget) => controller != oldWidget.controller;
}
