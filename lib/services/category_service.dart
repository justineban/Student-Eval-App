import '../models/category.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final Map<String, List<Category>> _courseCategories = {};

  List<Category> getCategoriesForCourse(String courseId) {
    return _courseCategories[courseId] ?? [];
  }

  Category? getCategory(String courseId, String categoryId) {
    final categories = _courseCategories[courseId] ?? [];
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  Future<Category> addCategory(
    String courseId,
    String name,
    String groupingMethod,
    int maxStudentsPerGroup,
  ) async {
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      name: name,
      groupingMethod: groupingMethod,
      maxStudentsPerGroup: maxStudentsPerGroup,
    );

    _courseCategories[courseId] ??= [];
    _courseCategories[courseId]!.add(category);
    return category;
  }

  bool updateCategory(String courseId, Category updatedCategory) {
    final categories = _courseCategories[courseId];
    if (categories == null) return false;

    final index = categories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index == -1) return false;

    categories[index] = updatedCategory;
    return true;
  }

  bool deleteCategory(String courseId, String categoryId) {
    final categories = _courseCategories[courseId];
    if (categories == null) return false;

    final initialLength = categories.length;
    categories.removeWhere((cat) => cat.id == categoryId);
    return categories.length < initialLength;
  }
}
