import '../entities/group.dart';
import '../repositories/group_repository.dart';

class ListGroupsForCategoryUseCase {
  final GroupRepository groupRepository;
  ListGroupsForCategoryUseCase(this.groupRepository);

  Future<List<GroupEntity>> call(String categoryId) => groupRepository.listByCategory(categoryId);
}
