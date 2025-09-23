import '../repositories/course_repository.dart';
import '../models/course_model.dart';

class InviteStudentUseCase {
  final CourseRepository repository;
  InviteStudentUseCase(this.repository);

  Future<CourseModel> call({required String courseId, required String teacherId, required String email}) {
    // Aquí se pueden añadir validaciones adicionales (formato de email, existencia de usuario, etc.)
    return repository.inviteStudent(courseId: courseId, teacherId: teacherId, email: email);
  }
}
