import '../repositories/course_repository.dart';

class InviteStudentToCourse {
  final CourseRepository repo;
  InviteStudentToCourse(this.repo);

  Future<void> call({required String courseId, required String email}) =>
      repo.addInvitation(courseId, email);
}
