import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../features/auth/data/datasources/local/hive_auth_local_data_source.dart';
import '../../features/courses/data/datasources/local/hive_course_local_data_source.dart';
import '../../features/courses/data/datasources/local/hive_category_local_data_source.dart';
import '../../features/courses/data/datasources/local/hive_group_local_data_source.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/courses/data/repositories/course_repository_impl.dart';
import '../../features/courses/data/repositories/category_repository_impl.dart';
import '../../features/courses/data/repositories/group_repository_impl.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/courses/domain/repositories/course_repository.dart';
import '../../features/courses/domain/repositories/category_repository.dart';
import '../../features/courses/domain/repositories/group_repository.dart';

import '../../core/generators/generators.dart';

// Use cases
import '../../features/courses/domain/use_cases/create_course.dart';
import '../../features/courses/domain/use_cases/invite_student.dart';
import '../../features/courses/domain/use_cases/enroll_by_code.dart';
import '../../features/courses/domain/use_cases/accept_invitation.dart';
import '../../features/courses/domain/use_cases/list_invitations_by_email.dart';
import '../../features/courses/domain/use_cases/list_courses_by_teacher.dart';
import '../../features/courses/domain/use_cases/list_courses_by_student.dart';

import '../../features/courses/domain/use_cases/create_category.dart';
import '../../features/courses/domain/use_cases/update_category.dart';
import '../../features/courses/domain/use_cases/delete_category.dart';
import '../../features/courses/domain/use_cases/list_categories_for_course.dart';

import '../../features/courses/domain/use_cases/list_groups_for_category.dart';
import '../../features/courses/domain/use_cases/join_group.dart';
import '../../features/courses/domain/use_cases/leave_group.dart';

import '../../features/auth/domain/use_cases/login_user.dart';
import '../../features/auth/domain/use_cases/register_user.dart';
import '../../features/auth/domain/use_cases/logout_user.dart';
import '../../features/auth/domain/use_cases/get_current_user_id.dart';

// Controllers
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/courses/presentation/controllers/teacher_courses_controller.dart';
import '../../features/courses/presentation/controllers/student_courses_controller.dart';
import '../../features/courses/presentation/controllers/categories_controller.dart';
import '../../features/courses/presentation/controllers/groups_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Data sources (assume Hive boxes already opened elsewhere in main)
    Get.lazyPut(() => HiveAuthLocalDataSource(usersBox: Hive.box('users'), sessionBox: Hive.box('session')));
    Get.lazyPut(() => HiveCourseLocalDataSource(Hive.box('courses')));
    Get.lazyPut(() => HiveCategoryLocalDataSource(Hive.box('categories')));
    Get.lazyPut(() => HiveGroupLocalDataSource(Hive.box('groups')));

    // Repositories
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(Get.find()));
    Get.lazyPut<CourseRepository>(() => CourseRepositoryImpl(coursesLocal: Get.find(), authLocal: Get.find()));
    Get.lazyPut<CategoryRepository>(() => CategoryRepositoryImpl(Get.find()));
    Get.lazyPut<GroupRepository>(() => GroupRepositoryImpl(Get.find()));

    // Generators
    Get.lazyPut<IdGenerator>(() => defaultIdGenerator);
    Get.lazyPut<CodeGenerator>(() => defaultCourseCodeGenerator);

    // Use cases (Courses / Auth / Categories / Groups)
    Get.lazyPut(() => CreateCourse(Get.find()));
    Get.lazyPut(() => InviteStudentToCourse(Get.find()));
    Get.lazyPut(() => EnrollInCourseByCode(Get.find()));
    Get.lazyPut(() => AcceptInvitationUseCase(Get.find()));
    Get.lazyPut(() => ListInvitationsByEmailUseCase(Get.find()));
    Get.lazyPut(() => ListCoursesByTeacherUseCase(Get.find()));
    Get.lazyPut(() => ListCoursesByStudentUseCase(Get.find()));

    Get.lazyPut(() => CreateCategoryUseCase(Get.find()));
    Get.lazyPut(() => UpdateCategoryUseCase(Get.find()));
    Get.lazyPut(() => DeleteCategoryUseCase(Get.find(), Get.find()));
    Get.lazyPut(() => ListCategoriesForCourseUseCase(Get.find()));

    Get.lazyPut(() => ListGroupsForCategoryUseCase(Get.find()));
    Get.lazyPut(() => JoinGroupUseCase(Get.find()));
    Get.lazyPut(() => LeaveGroupUseCase(Get.find()));

  Get.lazyPut(() => LoginUser(Get.find()));
  Get.lazyPut(() => RegisterUser(Get.find()));
  Get.lazyPut(() => LogoutUser(Get.find()));
  Get.lazyPut(() => GetCurrentUserId(Get.find()));

    // Controllers
    Get.lazyPut(() => AuthController(
          login: Get.find(),
          register: Get.find(),
          logout: Get.find(),
          getCurrentUserId: Get.find(),
        ));

    Get.lazyPut(() => TeacherCoursesController(
          createCourse: Get.find(),
          listByTeacher: Get.find(),
          inviteStudent: Get.find(),
          listInvitationsByEmail: Get.find(),
          idGenerator: Get.find(),
          codeGenerator: Get.find(),
        ));

    Get.lazyPut(() => StudentCoursesController(
          enrollByCode: Get.find(),
          listByStudent: Get.find(),
          acceptInvitation: Get.find(),
          listInvitationsByEmail: Get.find(),
        ));

    Get.lazyPut(() => CategoriesController(
          listCategories: Get.find(),
          createCategory: Get.find(),
          updateCategory: Get.find(),
          deleteCategory: Get.find(),
          idGenerator: Get.find(),
        ));

    Get.lazyPut(() => GroupsController(
          listGroups: Get.find(),
          joinGroup: Get.find(),
          leaveGroup: Get.find(),
        ));
  }
}
