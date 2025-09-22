import 'package:get/get.dart';
import 'package:proyecto_movil/features/auth/domain/use_cases/login_user.dart';
import 'package:proyecto_movil/features/auth/domain/use_cases/register_user.dart';
import 'package:proyecto_movil/features/auth/domain/use_cases/logout_user.dart';
import 'package:proyecto_movil/features/auth/domain/use_cases/get_current_user_id.dart';

class AuthController extends GetxController {
  final LoginUser login;
  final RegisterUser register;
  final LogoutUser logout;
  final GetCurrentUserId getCurrentUserId;

  AuthController({required this.login, required this.register, required this.logout, required this.getCurrentUserId});

  final RxnString currentUserId = RxnString();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    currentUserId.value = getCurrentUserId();
  }

  Future<bool> loginUser(String email, String password) async {
    isLoading.value = true; error.value = null;
    try {
      final id = await login(email: email, password: password);
      currentUserId.value = id;
      return id != null;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally { isLoading.value = false; }
  }

  Future<bool> registerUser(String email, String password, String name) async {
    isLoading.value = true; error.value = null;
    try {
      final id = await register(email: email, password: password, name: name);
      currentUserId.value = id;
      return id != null;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally { isLoading.value = false; }
  }

  Future<void> logoutUser() async {
    await logout();
    currentUserId.value = null;
  }

  bool get isLoggedIn => currentUserId.value != null;
}
