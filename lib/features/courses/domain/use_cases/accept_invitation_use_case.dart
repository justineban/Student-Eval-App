import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class AcceptInvitationUseCase {
  final CourseRepository repository;
  AcceptInvitationUseCase(this.repository);

  Future<CourseModel?> call({required String courseId, required String email, required String studentId}) {
    return repository.acceptInvitation(courseId: courseId, email: email, studentId: studentId);
  }
}
