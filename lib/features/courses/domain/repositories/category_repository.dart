import '../entities/category.dart';

abstract class CategoryRepository {
  Future<CategoryEntity> create(CategoryEntity category);
  Future<CategoryEntity?> getById(String id);
  Future<void> save(CategoryEntity category);
  Future<void> delete(String id);
  Future<List<CategoryEntity>> listByCourse(String courseId);
}
