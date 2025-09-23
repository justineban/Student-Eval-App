import '../repositories/course_repository.dart';
import '../models/course_model.dart';

class CreateCourseUseCase {
  final CourseRepository repository;
  CreateCourseUseCase(this.repository);

  Future<CourseModel> call({required String name, required String description, required String teacherId}) {
    return repository.createCourse(name: name, description: description, teacherId: teacherId);
  }
}
