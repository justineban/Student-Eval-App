import '../repositories/group_repository.dart';
import '../models/group_model.dart';

class GetCourseGroupsUseCase {
  final CourseGroupRepository repository;
  GetCourseGroupsUseCase(this.repository);

  Future<List<GroupModel>> call(String categoryId) => repository.listByCategory(categoryId);
}
