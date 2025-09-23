import 'package:get/get.dart';
import '../../domain/models/course_model.dart';
import '../../domain/use_cases/create_course_use_case.dart';
import '../../domain/use_cases/get_teacher_courses_use_case.dart';
import '../../domain/use_cases/invite_student_use_case.dart';

class CourseController extends GetxController {
  final CreateCourseUseCase createCourseUseCase;
  final GetTeacherCoursesUseCase getTeacherCoursesUseCase;
  final InviteStudentUseCase inviteStudentUseCase;
  CourseController({required this.createCourseUseCase, required this.getTeacherCoursesUseCase, required this.inviteStudentUseCase});

  final loading = false.obs;
  final courses = <CourseModel>[].obs;
  final error = RxnString();
  final inviteLoading = false.obs;
  final inviteError = RxnString();

  Future<void> inviteStudent({required String courseId, required String teacherId, required String email}) async {
    inviteLoading.value = true;
    inviteError.value = null;
    try {
      final updated = await inviteStudentUseCase(courseId: courseId, teacherId: teacherId, email: email);
      final idx = courses.indexWhere((c) => c.id == updated.id);
      if (idx != -1) {
        courses[idx] = updated;
        courses.refresh();
      }
    } catch (e) {
      inviteError.value = 'No se pudo invitar';
    } finally {
      inviteLoading.value = false;
    }
  }

  Future<void> loadTeacherCourses(String teacherId) async {
    loading.value = true;
    error.value = null;
    try {
      final list = await getTeacherCoursesUseCase(teacherId);
      courses.assignAll(list);
    } catch (e) {
      error.value = 'Error cargando cursos';
    } finally {
      loading.value = false;
    }
  }

  Future<CourseModel?> createCourse({required String name, required String description, required String teacherId}) async {
    loading.value = true;
    error.value = null;
    try {
      final course = await createCourseUseCase(name: name, description: description, teacherId: teacherId);
      courses.add(course);
      return course;
    } catch (e) {
      error.value = 'Error creando curso';
      return null;
    } finally {
      loading.value = false;
    }
  }
}
