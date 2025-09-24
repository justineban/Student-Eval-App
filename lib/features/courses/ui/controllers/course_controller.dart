import 'package:get/get.dart';
import '../../domain/models/course_model.dart';
import '../../domain/use_cases/create_course_use_case.dart';
import '../../domain/use_cases/get_teacher_courses_use_case.dart';
import '../../domain/use_cases/invite_student_use_case.dart';
import '../../domain/use_cases/update_course_use_case.dart';
import '../../domain/use_cases/delete_course_use_case.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';

class CourseController extends GetxController {
  final CreateCourseUseCase createCourseUseCase;
  final GetTeacherCoursesUseCase getTeacherCoursesUseCase;
  final InviteStudentUseCase inviteStudentUseCase;
  final UpdateCourseUseCase updateCourseUseCase;
  final DeleteCourseUseCase deleteCourseUseCase;
  CourseController({
    required this.createCourseUseCase,
    required this.getTeacherCoursesUseCase,
    required this.inviteStudentUseCase,
    required this.updateCourseUseCase,
    required this.deleteCourseUseCase,
  });

  final loading = false.obs;
  final courses = <CourseModel>[].obs;
  final error = RxnString();
  final inviteLoading = false.obs;
  final inviteError = RxnString();
  final updating = false.obs;
  final deleting = false.obs;

  Future<void> inviteStudent({required String courseId, required String teacherId, required String email}) async {
    inviteLoading.value = true;
    inviteError.value = null;
    try {
      // Validate that the target email belongs to a registered user
      final authLocal = Get.find<AuthLocalDataSource>();
      final trimmed = email.trim();
      var target = await authLocal.fetchUserByEmail(trimmed);
      if (target == null) {
        target = await authLocal.fetchUserByEmail(trimmed.toLowerCase());
      }
      if (target == null) {
        inviteError.value = 'El correo no pertenece a ningún usuario registrado';
        return;
      }

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

  Future<CourseModel?> updateCourse({required String id, required String name, required String description, required String teacherId}) async {
    updating.value = true; error.value = null;
    try {
      final updated = await updateCourseUseCase(id: id, name: name, description: description, teacherId: teacherId);
      final idx = courses.indexWhere((c) => c.id == id);
      if (idx != -1) courses[idx] = updated;
      return updated;
    } catch (e) {
      error.value = 'Error actualizando curso';
      return null;
    } finally {
      updating.value = false;
    }
  }

  Future<bool> deleteCourse({required String id, required String teacherId}) async {
    deleting.value = true; error.value = null;
    try {
      await deleteCourseUseCase(id: id, teacherId: teacherId);
      courses.removeWhere((c) => c.id == id);
      return true;
    } catch (e) {
      error.value = 'Error eliminando curso';
      return false;
    } finally {
      deleting.value = false;
    }
  }
}
