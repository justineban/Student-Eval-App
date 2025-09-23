import '../repositories/group_repository.dart';
import '../models/group_model.dart';

class CreateCourseGroupUseCase {
  final CourseGroupRepository repository;
  CreateCourseGroupUseCase(this.repository);

  Future<GroupModel> call({required String courseId, required String categoryId, required String name}) {
    if (name.trim().isEmpty) throw ArgumentError('Nombre requerido');
    return repository.create(courseId: courseId, categoryId: categoryId, name: name.trim());
  }
}
