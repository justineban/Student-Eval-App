import 'package:get/get.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../courses/data/datasources/course_local_datasource.dart';
import '../../../courses/data/repositories/course_repository_impl.dart';
import '../../../courses/domain/repositories/course_repository.dart';
import '../../../courses/domain/use_cases/create_course_use_case.dart';
import '../../../courses/domain/use_cases/get_teacher_courses_use_case.dart';
import '../../../courses/domain/use_cases/invite_student_use_case.dart';
import '../../../courses/ui/controllers/course_controller.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/register_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/restore_session_use_case.dart';
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
  Get.lazyPut(() => RestoreSessionUseCase(Get.find<AuthRepository>()), fenix: true);

    // Controller
    Get.put(AuthController(
      loginUseCase: Get.find(),
      registerUseCase: Get.find(),
      logoutUseCase: Get.find(),
      restoreSessionUseCase: Get.find(),
    ));

    // Courses module (basic in-memory wiring for now)
  Get.lazyPut<CourseLocalDataSource>(() => HiveCourseLocalDataSource(), fenix: true);
  Get.lazyPut<CourseRemoteDataSource>(() => StubCourseRemoteDataSource(), fenix: true);
    Get.lazyPut<CourseRepository>(() {
      final local = Get.find<CourseLocalDataSource>();
      CourseRemoteDataSource? remote;
      if (Get.isRegistered<CourseRemoteDataSource>()) {
        remote = Get.find<CourseRemoteDataSource>();
      }
      return CourseRepositoryImpl(local: local, remote: remote);
    }, fenix: true);
    Get.lazyPut(() => CreateCourseUseCase(Get.find<CourseRepository>()), fenix: true);
    Get.lazyPut(() => GetTeacherCoursesUseCase(Get.find<CourseRepository>()), fenix: true);
    Get.lazyPut(() => InviteStudentUseCase(Get.find<CourseRepository>()), fenix: true);
    Get.put(CourseController(
      createCourseUseCase: Get.find(),
      getTeacherCoursesUseCase: Get.find(),
      inviteStudentUseCase: Get.find(),
    ), permanent: true);
  }
}
