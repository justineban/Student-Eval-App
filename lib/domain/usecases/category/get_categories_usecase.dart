import '../../models/category.dart';
import '../../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  List<Category> execute(String courseId) {
    return repository.getCategoriesForCourse(courseId);
  }
}
