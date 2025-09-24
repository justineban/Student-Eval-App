import '../models/group_model.dart';
import '../repositories/group_repository.dart';

class TrimGroupsToCapacityUseCase {
  final CourseGroupRepository repository;
  TrimGroupsToCapacityUseCase(this.repository);

  Future<List<GroupModel>> call({required String categoryId, required int maxPerGroup}) {
    if (maxPerGroup <= 0) {
      throw ArgumentError('maxPerGroup debe ser > 0');
    }
    return repository.trimGroupsToCapacity(categoryId: categoryId, maxPerGroup: maxPerGroup);
  }
}
