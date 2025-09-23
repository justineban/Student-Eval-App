import '../models/category_model.dart';

abstract class CategoryRepository {
  Future<CategoryModel> createCategory({required String courseId, required String name, required bool randomGroups, required int maxStudentsPerGroup});
  Future<List<CategoryModel>> getCategoriesByCourse(String courseId);
  Future<CategoryModel?> getCategory(String id);
}
