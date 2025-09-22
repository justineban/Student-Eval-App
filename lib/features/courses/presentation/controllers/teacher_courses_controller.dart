import 'package:get/get.dart';

import '../../domain/entities/course.dart';
import '../../domain/use_cases/create_course.dart';
import '../../domain/use_cases/list_courses_by_teacher.dart';
import '../../domain/use_cases/invite_student.dart';
import '../../domain/use_cases/list_invitations_by_email.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/generators/generators.dart';

class TeacherCoursesController extends GetxController {
  final CreateCourse createCourse;
  final ListCoursesByTeacherUseCase listByTeacher;
  final InviteStudentToCourse inviteStudent;
  final ListInvitationsByEmailUseCase listInvitationsByEmail;
  final IdGenerator idGenerator; // Provided for uniform interface though CreateCourse expects fn only at call
  final CodeGenerator codeGenerator;

  TeacherCoursesController({
    required this.createCourse,
    required this.listByTeacher,
    required this.inviteStudent,
    required this.listInvitationsByEmail,
    required this.idGenerator,
    required this.codeGenerator,
  });

  final RxList<CourseEntity> courses = <CourseEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  AuthController get auth => Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final teacherId = auth.currentUserId.value;
    if (teacherId == null) return;
    isLoading.value = true; error.value = null;
    try {
      courses.value = await listByTeacher(teacherId);
    } catch (e) {
      error.value = e.toString();
    } finally { isLoading.value = false; }
  }

  Future<CourseEntity?> createNewCourse({required String name, required String description}) async {
    final teacherId = auth.currentUserId.value;
    if (teacherId == null) return null;
    isLoading.value = true; error.value = null;
    try {
      final course = await createCourse(
        name: name,
        description: description,
        teacherId: teacherId,
        idGenerator: idGenerator,
        codeFromId: (id) => codeGenerator(),
      );
      courses.add(course);
      return course;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally { isLoading.value = false; }
  }

  Future<bool> invite(String courseId, String email) async {
    try {
      await inviteStudent(courseId: courseId, email: email);
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    }
  }

  Future<void> refreshCourses() => _load();
}
