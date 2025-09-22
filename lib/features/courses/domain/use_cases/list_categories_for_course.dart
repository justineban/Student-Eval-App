import '../entities/category.dart';
import '../repositories/category_repository.dart';

class ListCategoriesForCourseUseCase {
  final CategoryRepository categoryRepository;
  ListCategoriesForCourseUseCase(this.categoryRepository);

  Future<List<CategoryEntity>> call(String courseId) => categoryRepository.listByCourse(courseId);
}
