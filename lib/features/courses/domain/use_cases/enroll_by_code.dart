import '../entities/course.dart';
import '../repositories/course_repository.dart';

class EnrollInCourseByCode {
  final CourseRepository repo;
  EnrollInCourseByCode(this.repo);

  Future<CourseEntity?> call({required String code, required String userId}) async {
    final course = await repo.getByRegistrationCode(code);
    if (course == null) return null;
    if (!course.studentIds.contains(userId)) {
      final updated = course.copyWith(studentIds: [...course.studentIds, userId]);
      await repo.save(updated);
      return updated;
    }
    return course;
  }
}
