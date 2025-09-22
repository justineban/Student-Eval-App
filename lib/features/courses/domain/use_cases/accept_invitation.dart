import '../repositories/course_repository.dart';

class AcceptInvitationUseCase {
  final CourseRepository courseRepository;
  AcceptInvitationUseCase(this.courseRepository);

  Future<bool> call({required String courseId, required String userId, required String userEmail}) async {
    final course = await courseRepository.getById(courseId);
    if (course == null) return false;
    if (!course.invitations.contains(userEmail)) return false;

    // remove invitation and add student if not present
    final updated = course.copyWith(
      invitations: List<String>.from(course.invitations)..remove(userEmail),
      studentIds: course.studentIds.contains(userId)
          ? course.studentIds
          : (List<String>.from(course.studentIds)..add(userId)),
    );
    await courseRepository.save(updated);
    return true;
  }
}
