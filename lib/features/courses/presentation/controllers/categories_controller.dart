import 'package:get/get.dart';

import '../../domain/entities/category.dart';
import '../../domain/use_cases/list_categories_for_course.dart';
import '../../domain/use_cases/create_category.dart';
import '../../domain/use_cases/update_category.dart';
import '../../domain/use_cases/delete_category.dart';
import '../../../../core/generators/generators.dart';

class CategoriesController extends GetxController {
  final ListCategoriesForCourseUseCase listCategories;
  final CreateCategoryUseCase createCategory;
  final UpdateCategoryUseCase updateCategory;
  final DeleteCategoryUseCase deleteCategory;
  final IdGenerator idGenerator;

  CategoriesController({
    required this.listCategories,
    required this.createCategory,
    required this.updateCategory,
    required this.deleteCategory,
    required this.idGenerator,
  });

  final RxList<CategoryEntity> categories = <CategoryEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  String? _courseId;

  Future<void> load(String courseId) async {
    _courseId = courseId;
    isLoading.value = true; error.value = null;
    try {
      categories.value = await listCategories(courseId);
    } catch (e) {
      error.value = e.toString();
    } finally { isLoading.value = false; }
  }

  Future<CategoryEntity?> createNew({required String name, bool randomAssign = false, int? studentsPerGroup}) async {
    final courseId = _courseId; if (courseId == null) return null;
    try {
      final category = CategoryEntity(
        id: idGenerator(),
        courseId: courseId,
        name: name,
        randomAssign: randomAssign,
        studentsPerGroup: studentsPerGroup ?? 0,
      );
      final created = await createCategory(category);
      categories.add(created);
      return created;
    } catch (e) { error.value = e.toString(); return null; }
  }

  Future<CategoryEntity?> updateOne(String id, {String? name, bool? randomAssign, int? studentsPerGroup}) async {
    try {
      final updated = await updateCategory(id, name: name, randomAssign: randomAssign, studentsPerGroup: studentsPerGroup);
      if (updated != null) {
        final idx = categories.indexWhere((c) => c.id == id);
        if (idx != -1) categories[idx] = updated;
      }
      return updated;
    } catch (e) { error.value = e.toString(); return null; }
  }

  Future<bool> deleteOne(String id) async {
    try {
      await deleteCategory(id);
      categories.removeWhere((c) => c.id == id);
      return true;
    } catch (e) { error.value = e.toString(); return false; }
  }
}
