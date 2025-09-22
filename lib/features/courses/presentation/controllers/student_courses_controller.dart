import 'package:get/get.dart';

import '../../domain/entities/course.dart';
import '../../domain/use_cases/enroll_by_code.dart';
import '../../domain/use_cases/list_courses_by_student.dart';
import '../../domain/use_cases/accept_invitation.dart';
import '../../domain/use_cases/list_invitations_by_email.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class StudentCoursesController extends GetxController {
  final EnrollInCourseByCode enrollByCode;
  final ListCoursesByStudentUseCase listByStudent;
  final AcceptInvitationUseCase acceptInvitation;
  final ListInvitationsByEmailUseCase listInvitationsByEmail;

  StudentCoursesController({
    required this.enrollByCode,
    required this.listByStudent,
    required this.acceptInvitation,
    required this.listInvitationsByEmail,
  });

  final RxList<CourseEntity> courses = <CourseEntity>[].obs;
  final RxList<CourseEntity> invitations = <CourseEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  AuthController get auth => Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final userId = auth.currentUserId.value;
    if (userId == null) return;
    isLoading.value = true; error.value = null;
    try {
      courses.value = await listByStudent(userId);
      final email = userId; // If userId is not email we need mapping; placeholder assumption
      invitations.value = await listInvitationsByEmail(email);
    } catch (e) {
      error.value = e.toString();
    } finally { isLoading.value = false; }
  }

  Future<CourseEntity?> enroll(String code) async {
    final userId = auth.currentUserId.value;
    if (userId == null) return null;
    isLoading.value = true; error.value = null;
    try {
      final course = await enrollByCode(code: code, userId: userId);
      if (course != null && !courses.any((c) => c.id == course.id)) {
        courses.add(course);
      }
      return course;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally { isLoading.value = false; }
  }

  Future<bool> accept(String courseId) async {
    final userId = auth.currentUserId.value;
    if (userId == null) return false;
    // We need the user email for invitation, currently AuthController only exposes id.
    // TODO: Replace with actual email retrieval when AuthController supports it.
    final email = userId; // temporary assumption
    try {
      final ok = await acceptInvitation(courseId: courseId, userId: userId, userEmail: email);
      if (ok) {
        await _load();
      }
      return ok;
    } catch (e) {
      error.value = e.toString();
      return false;
    }
  }

  Future<void> refreshAll() => _load();
}
