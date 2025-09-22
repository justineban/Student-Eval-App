import '../entities/course.dart';
import '../repositories/course_repository.dart';

class CreateCourse {
  final CourseRepository repo;
  CreateCourse(this.repo);

  Future<CourseEntity> call({
    required String name,
    required String description,
    required String teacherId,
    required String Function() idGenerator,
    required String Function(String id) codeFromId,
  }) async {
    final id = idGenerator();
    final code = codeFromId(id);
    final course = CourseEntity(
      id: id,
      name: name,
      description: description,
      teacherId: teacherId,
      registrationCode: code,
      studentIds: const [],
      invitations: const [],
    );
    return repo.create(course);
  }
}
