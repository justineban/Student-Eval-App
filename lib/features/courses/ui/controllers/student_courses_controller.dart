import 'package:get/get.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../domain/models/course_model.dart';
import '../../domain/use_cases/join_course_by_code_use_case.dart';
import '../../domain/use_cases/get_student_courses_use_case.dart';
import '../../domain/use_cases/get_invited_courses_use_case.dart';
import '../../domain/use_cases/accept_invitation_use_case.dart';

class StudentCoursesController extends GetxController {
  final JoinCourseByCodeUseCase joinByCodeUseCase;
  final GetStudentCoursesUseCase getStudentCoursesUseCase;
  final GetInvitedCoursesUseCase getInvitedCoursesUseCase;
  final AcceptInvitationUseCase acceptInvitationUseCase;

  StudentCoursesController({
    required this.joinByCodeUseCase,
    required this.getStudentCoursesUseCase,
    required this.getInvitedCoursesUseCase,
    required this.acceptInvitationUseCase,
  });

  final loading = false.obs;
  final error = RxnString();
  final enrolled = <CourseModel>[].obs;
  final invites = <CourseModel>[].obs;

  String? get _studentId => Get.find<AuthController>().currentUser.value?.id;
  String? get _studentEmail => Get.find<AuthController>().currentUser.value?.email;

  Future<void> refreshData() async {
    final id = _studentId;
    if (id == null) return;
    loading.value = true;
    try {
      enrolled.value = await getStudentCoursesUseCase(id);
      final email = _studentEmail;
      if (email != null && email.isNotEmpty) {
        invites.value = await getInvitedCoursesUseCase(email);
      } else {
        invites.clear();
      }
    } finally {
      loading.value = false;
    }
  }

  Future<CourseModel?> joinByCode(String code) async {
    final id = _studentId;
    if (id == null) return null;
    error.value = null;
    if (code.trim().isEmpty) {
      error.value = 'Ingresa un código';
      return null;
    }
    loading.value = true;
    try {
      final course = await joinByCodeUseCase(code: code, studentId: id);
      if (course == null) {
        error.value = 'Código inválido';
      } else {
        await refreshData();
      }
      return course;
    } finally {
      loading.value = false;
    }
  }

  Future<CourseModel?> acceptInvite(String courseId) async {
    final id = _studentId;
    final email = _studentEmail;
    if (id == null || email == null) return null;
    loading.value = true;
    try {
      final course = await acceptInvitationUseCase(courseId: courseId, email: email, studentId: id);
      await refreshData();
      return course;
    } finally {
      loading.value = false;
    }
  }
}
