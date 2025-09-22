import '../repositories/category_repository.dart';
import '../repositories/group_repository.dart';

class DeleteCategoryUseCase {
  final CategoryRepository categoryRepository;
  final GroupRepository groupRepository;
  DeleteCategoryUseCase(this.categoryRepository, this.groupRepository);

  Future<void> call(String id) async {
    // Cascade delete groups
    await groupRepository.deleteByCategory(id);
    await categoryRepository.delete(id);
  }
}
