import '../repositories/group_repository.dart';

class DeleteCourseGroupUseCase {
  final CourseGroupRepository repository;
  DeleteCourseGroupUseCase(this.repository);

  Future<void> call(String id) => repository.delete(id);
}
