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
import '../../../assessments/domain/repositories/category_repository.dart';
import '../../../assessments/domain/repositories/activity_repository.dart';
import '../../../assessments/data/datasources/category_local_datasource.dart';
import '../../../assessments/data/datasources/activity_local_datasource.dart';
import '../../../assessments/data/repositories/category_repository_impl.dart';
import '../../../assessments/data/repositories/activity_repository_impl.dart';
import '../../../assessments/domain/use_cases/create_category_use_case.dart';
import '../../../assessments/domain/use_cases/get_categories_use_case.dart';
import '../../../assessments/domain/use_cases/create_activity_use_case.dart';
import '../../../assessments/domain/use_cases/get_activities_use_case.dart';
import '../../../assessments/ui/controllers/category_controller.dart';
import '../../../assessments/ui/controllers/activity_controller.dart';
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

    // Assessments / Categories / Activities
    Get.lazyPut<CategoryLocalDataSource>(() => HiveCategoryLocalDataSource(), fenix: true);
    Get.lazyPut<ActivityLocalDataSource>(() => HiveActivityLocalDataSource(), fenix: true);
    Get.lazyPut<CategoryRepository>(() => CategoryRepositoryImpl(local: Get.find()), fenix: true);
    Get.lazyPut<ActivityRepository>(() => ActivityRepositoryImpl(local: Get.find()), fenix: true);
    Get.lazyPut(() => CreateCategoryUseCase(Get.find<CategoryRepository>()), fenix: true);
    Get.lazyPut(() => GetCategoriesUseCase(Get.find<CategoryRepository>()), fenix: true);
    Get.lazyPut(() => CreateActivityUseCase(activityRepository: Get.find<ActivityRepository>(), categoryRepository: Get.find<CategoryRepository>()), fenix: true);
    Get.lazyPut(() => GetActivitiesUseCase(Get.find<ActivityRepository>()), fenix: true);

    // Controllers for assessments domain
    Get.put(CategoryController(createCategoryUseCase: Get.find(), getCategoriesUseCase: Get.find()), permanent: true);
    Get.put(ActivityController(createActivityUseCase: Get.find(), getActivitiesUseCase: Get.find()), permanent: true);
  }
}
