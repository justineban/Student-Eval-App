import '../repositories/course_repository.dart';

class DeleteCourseUseCase {
  final CourseRepository repository;
  DeleteCourseUseCase(this.repository);

  Future<void> call({required String id, required String teacherId}) {
    return repository.deleteCourse(id: id, teacherId: teacherId);
  }
}
