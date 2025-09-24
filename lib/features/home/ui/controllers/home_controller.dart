import 'package:get/get.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../auth/ui/pages/login_page.dart';
import '../../../courses/ui/pages/course_list_page.dart';
import '../../../courses/ui/pages/add_course_page.dart';
import '../../../courses/ui/pages/enroll_course_page.dart';
import '../../../courses/ui/pages/enrolled_courses_page.dart';
import '../../../groups/ui/pages/my_groups_page.dart';
import '../../../grades/ui/pages/my_grades_page.dart';
import '../../../activities/ui/pages/my_activities_page.dart';
import '../../../reports/ui/pages/teacher_courses_report_page.dart';

/// HomeController orchestrates high-level navigation intents (placeholder for now).
class HomeController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  String get userName => authController.currentUser.value?.name ?? 'Usuario';

  void goToCourses() {
    Get.to(() => const CourseListPage());
  }

  void goToAssessments() {
    // TODO: implement navigation to assessments module
  }

  void goToCreateCourse() {
    Get.to(() => const AddCoursePage());
  }

  void goToEnrollCourse() {
    Get.to(() => const EnrollCoursePage());
  }

  void goToEnrolledCourses() {
    Get.to(() => const EnrolledCoursesPage());
  }

  void goToMyGroups() {
    Get.to(() => const MyGroupsPage());
  }

  void goToMyGrades() {
    Get.to(() => const MyGradesPage());
  }

  void goToMyActivities() {
    Get.to(() => const MyActivitiesPage());
  }

  void goToTeacherCoursesReport() {
    Get.to(() => const TeacherCoursesReportPage());
  }

  Future<void> logout() async {
    await authController.logout();
    Get.offAll(() => const LoginPage());
  }
}
