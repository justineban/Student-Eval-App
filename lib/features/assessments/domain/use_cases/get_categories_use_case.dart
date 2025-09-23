import '../repositories/category_repository.dart';
import '../models/category_model.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<List<CategoryModel>> call(String courseId) => repository.getCategoriesByCourse(courseId);
}
