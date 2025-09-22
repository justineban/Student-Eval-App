import '../entities/category.dart';
import '../repositories/category_repository.dart';

class CreateCategoryUseCase {
  final CategoryRepository categoryRepository;
  CreateCategoryUseCase(this.categoryRepository);

  Future<CategoryEntity> call(CategoryEntity category) {
    return categoryRepository.create(category);
  }
}
