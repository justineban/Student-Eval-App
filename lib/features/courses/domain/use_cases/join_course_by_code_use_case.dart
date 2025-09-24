import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class JoinCourseByCodeUseCase {
  final CourseRepository repository;
  JoinCourseByCodeUseCase(this.repository);

  Future<CourseModel?> call({required String code, required String studentId}) {
    return repository.joinCourseByCode(code: code, studentId: studentId);
  }
}
