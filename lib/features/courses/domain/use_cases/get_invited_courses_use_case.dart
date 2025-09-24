import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class GetInvitedCoursesUseCase {
  final CourseRepository repository;
  GetInvitedCoursesUseCase(this.repository);

  Future<List<CourseModel>> call(String email) {
    return repository.getInvitedCoursesForEmail(email);
  }
}
