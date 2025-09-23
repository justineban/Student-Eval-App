import '../repositories/group_repository.dart';
import '../models/group_model.dart';

class GetGroupsUseCase {
  final GroupRepository repository;
  GetGroupsUseCase(this.repository);

  Future<List<GroupModel>> call(String categoryId) => repository.getGroupsByCategory(categoryId);
}
