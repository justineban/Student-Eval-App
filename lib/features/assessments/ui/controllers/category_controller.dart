import 'package:get/get.dart';
import '../../domain/models/category_model.dart';
import '../../domain/use_cases/create_category_use_case.dart';
import '../../domain/use_cases/get_categories_use_case.dart';
import '../../domain/use_cases/update_category_use_case.dart';
import '../../domain/use_cases/delete_category_use_case.dart';
import '../../../courses/ui/controllers/group_controller.dart';

class CategoryController extends GetxController {
  final CreateCategoryUseCase createCategoryUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final UpdateCategoryUseCase updateCategoryUseCase;
  final DeleteCategoryUseCase deleteCategoryUseCase;
  CategoryController({
    required this.createCategoryUseCase,
    required this.getCategoriesUseCase,
    required this.updateCategoryUseCase,
    required this.deleteCategoryUseCase,
  });

  final categories = <CategoryModel>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final creating = false.obs;
  final updating = false.obs;
  final deleting = false.obs;

  Future<void> load(String courseId) async {
    loading.value = true;
    error.value = null;
    try {
      final list = await getCategoriesUseCase(courseId);
      categories.assignAll(list);
    } catch (e) {
      error.value = 'Error cargando categorías';
    } finally {
      loading.value = false;
    }
  }

  Future<CategoryModel?> create({
    required String courseId,
    required String name,
    required bool randomGroups,
    required int maxStudentsPerGroup,
  }) async {
    creating.value = true;
    error.value = null;
    try {
      final cat = await createCategoryUseCase(
        courseId: courseId,
        name: name,
        randomGroups: randomGroups,
        maxStudentsPerGroup: maxStudentsPerGroup,
      );
      categories.add(cat);
      // After creating category, ensure minimum groups for all students; and if random, distribute
      Future<void>(() async {
        try {
          if (Get.isRegistered<CourseGroupController>()) {
            final gc = Get.find<CourseGroupController>();
            await gc.ensureMinimumGroupsForCategory(courseId: courseId, categoryId: cat.id, maxPerGroup: maxStudentsPerGroup);
            if (randomGroups) {
              await gc.randomDistributeAllStudents(courseId: courseId, categoryId: cat.id, maxPerGroup: maxStudentsPerGroup);
            }
          }
        } catch (_) {}
      });
      return cat;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      creating.value = false;
    }
  }

  Future<CategoryModel?> updateCategory(CategoryModel category, {String? name, bool? randomGroups, int? maxStudentsPerGroup}) async {
    updating.value = true;
    error.value = null;
    try {
      final oldMax = category.maxStudentsPerGroup;
      final updated = await updateCategoryUseCase(
        category: category,
        name: name,
        randomGroups: randomGroups,
        maxStudentsPerGroup: maxStudentsPerGroup,
      );
      final idx = categories.indexWhere((c) => c.id == updated.id);
      if (idx != -1) {
        categories[idx] = updated; // triggers update
      }
      // End the updating spinner before any potentially long follow-up work
      updating.value = false;

      // If capacity decreased, trim over-capacity groups for this category in background (non-blocking)
      if (maxStudentsPerGroup != null && maxStudentsPerGroup < oldMax) {
        Future<void>(() async {
          try {
            if (Get.isRegistered<CourseGroupController>()) {
              final gc = Get.find<CourseGroupController>();
              await gc.trimOverCapacityGroups(updated.id, maxStudentsPerGroup);
            }
          } catch (_) {
            // Best-effort; ignore errors to avoid disrupting UX
          }
        });
      }

      // If random toggled on or max changed (increase), re-evaluate groups: ensure enough and redistribute for random
      Future<void>(() async {
        try {
          if (!Get.isRegistered<CourseGroupController>()) return;
          final gc = Get.find<CourseGroupController>();
          final max = maxStudentsPerGroup ?? updated.maxStudentsPerGroup;
          // Always ensure capacity after updates
          await gc.ensureMinimumGroupsForCategory(courseId: updated.courseId, categoryId: updated.id, maxPerGroup: max);
          // If category is random, distribute all students now
          final isRandom = randomGroups ?? updated.randomGroups;
          if (isRandom) {
            await gc.randomDistributeAllStudents(courseId: updated.courseId, categoryId: updated.id, maxPerGroup: max);
          }
        } catch (_) {}
      });
      return updated;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      // Keep false; if already set above it remains false.
      updating.value = false;
    }
  }

  Future<bool> delete(String id) async {
    deleting.value = true;
    error.value = null;
    try {
      await deleteCategoryUseCase(id);
      categories.removeWhere((c) => c.id == id);
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      deleting.value = false;
    }
  }

  void viewGroups(CategoryModel category) {
    Get.toNamed('/course-groups', arguments: {
      'courseId': category.courseId,
      'categoryId': category.id,
      'categoryName': category.name,
      'isManual': !category.randomGroups,
    });
  }
}
