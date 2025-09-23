import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final CategoryRepository repository;
  UpdateCategoryUseCase(this.repository);

  Future<CategoryModel> call({
    required CategoryModel category,
    String? name,
    bool? randomGroups,
    int? maxStudentsPerGroup,
  }) {
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Nombre requerido');
    }
    if (maxStudentsPerGroup != null && maxStudentsPerGroup <= 0) {
      throw ArgumentError('Máx. estudiantes debe ser > 0');
    }
    if (name != null) category.name = name.trim();
    if (randomGroups != null) category.randomGroups = randomGroups;
    if (maxStudentsPerGroup != null) category.maxStudentsPerGroup = maxStudentsPerGroup;
    return repository.updateCategory(category);
  }
}
