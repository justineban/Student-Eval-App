import '../entities/course.dart';
import '../repositories/course_repository.dart';

class ListInvitationsByEmailUseCase {
  final CourseRepository courseRepository;
  ListInvitationsByEmailUseCase(this.courseRepository);

  Future<List<CourseEntity>> call(String email) => courseRepository.listByInvitationEmail(email);
}
