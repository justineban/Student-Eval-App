import 'package:get/get.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/register_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Datasources (Hive-backed now; keep InMemory for tests if needed)
    Get.lazyPut<AuthLocalDataSource>(() => HiveAuthLocalDataSource(), fenix: true);
    Get.lazyPut<AuthRemoteDataSource>(() => StubAuthRemoteDataSource(), fenix: true);

    // Repository (bind to interface type so Get.find<AuthRepository>() works)
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(local: Get.find(), remote: Get.find()), fenix: true);

    // Use cases
    Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => RegisterUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()), fenix: true);

    // Controller
    Get.put(AuthController(
      loginUseCase: Get.find(),
      registerUseCase: Get.find(),
      logoutUseCase: Get.find(),
    ));
  }
}
