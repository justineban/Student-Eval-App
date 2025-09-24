import '../repositories/course_repository.dart';
import '../models/course_model.dart';

class UpdateCourseUseCase {
  final CourseRepository repository;
  UpdateCourseUseCase(this.repository);

  Future<CourseModel> call({required String id, required String name, required String description, required String teacherId}) {
    if (name.trim().isEmpty) throw ArgumentError('Nombre requerido');
    return repository.updateCourse(id: id, name: name.trim(), description: description.trim(), teacherId: teacherId);
  }
}
