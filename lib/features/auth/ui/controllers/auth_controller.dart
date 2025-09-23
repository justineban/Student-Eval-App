import 'package:get/get.dart';
import '../../domain/models/user_model.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/register_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/restore_session_use_case.dart';

/// Controller (presentation layer) to bridge UI events with use cases.
class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;

  AuthController({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.restoreSessionUseCase,
  });

  final loading = false.obs;
  final error = RxnString();
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _attemptRestore();
  }

  Future<void> _attemptRestore() async {
    loading.value = true;
    try {
      final restored = await restoreSessionUseCase();
      if (restored != null) {
        currentUser.value = restored;
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    loading.value = true;
    error.value = null;
    final result = await loginUseCase(email, password);
    if (result == null) {
      error.value = 'Credenciales inválidas o campos vacíos';
    } else {
      currentUser.value = result;
    }
    loading.value = false;
  }

  Future<void> register(String name, String email, String password) async {
    loading.value = true;
    error.value = null;
    final result = await registerUseCase(name: name, email: email, password: password);
    if (result == null) {
      error.value = 'No se pudo registrar (email en uso o datos inválidos)';
    } else {
      currentUser.value = result;
    }
    loading.value = false;
  }

  Future<void> logout() async {
    loading.value = true;
    await logoutUseCase();
    currentUser.value = null;
    loading.value = false;
  }
}
