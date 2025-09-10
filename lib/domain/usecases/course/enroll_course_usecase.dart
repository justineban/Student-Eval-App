import '../../repositories/course_repository.dart';

class EnrollCourseUseCase {
  final CourseRepository repository;

  EnrollCourseUseCase(this.repository);

  Future<bool> execute(String courseId, String userId) async {
    return await repository.enrollUser(courseId, userId);
  }
}
