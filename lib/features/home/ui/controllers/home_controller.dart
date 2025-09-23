import 'package:get/get.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../auth/ui/pages/login_page.dart';
import '../../../courses/ui/pages/course_list_page.dart';
import '../../../courses/ui/pages/add_course_page.dart';

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

  Future<void> logout() async {
    await authController.logout();
    Get.offAll(() => const LoginPage());
  }
}
