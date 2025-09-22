import '../entities/category.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final CategoryRepository categoryRepository;
  UpdateCategoryUseCase(this.categoryRepository);

  Future<CategoryEntity?> call(String id, {String? name, bool? randomAssign, int? studentsPerGroup}) async {
    final existing = await categoryRepository.getById(id);
    if (existing == null) return null;
    final updated = existing.copyWith(
      name: name,
      randomAssign: randomAssign,
      studentsPerGroup: studentsPerGroup,
    );
    await categoryRepository.save(updated);
    return updated;
  }
}
