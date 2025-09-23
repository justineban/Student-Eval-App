import '../repositories/category_repository.dart';
import '../models/category_model.dart';

class CreateCategoryUseCase {
  final CategoryRepository repository;
  CreateCategoryUseCase(this.repository);

  Future<CategoryModel> call({
    required String courseId,
    required String name,
    required bool randomGroups,
    required int maxStudentsPerGroup,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Nombre requerido');
    }
    if (maxStudentsPerGroup <= 0) {
      throw ArgumentError('Máx. estudiantes debe ser > 0');
    }
    return repository.createCategory(
      courseId: courseId,
      name: name.trim(),
      randomGroups: randomGroups,
      maxStudentsPerGroup: maxStudentsPerGroup,
    );
  }
}
