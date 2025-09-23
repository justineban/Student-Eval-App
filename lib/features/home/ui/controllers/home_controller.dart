import 'package:get/get.dart';
import '../../../auth/ui/controllers/auth_controller.dart';

/// HomeController orchestrates high-level navigation intents (placeholder for now).
class HomeController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  String get userName => authController.currentUser.value?.name ?? 'Usuario';

  void goToCourses() {
    // TODO: implement navigation to courses module
  }

  void goToAssessments() {
    // TODO: implement navigation to assessments module
  }

  Future<void> logout() async {
    await authController.logout();
    Get.offAllNamed('/login');
  }
}
