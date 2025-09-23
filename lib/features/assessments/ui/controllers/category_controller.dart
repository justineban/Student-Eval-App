import 'package:get/get.dart';
import '../../domain/models/category_model.dart';
import '../../domain/use_cases/create_category_use_case.dart';
import '../../domain/use_cases/get_categories_use_case.dart';

class CategoryController extends GetxController {
  final CreateCategoryUseCase createCategoryUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  CategoryController({required this.createCategoryUseCase, required this.getCategoriesUseCase});

  final categories = <CategoryModel>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final creating = false.obs;

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
      return cat;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      creating.value = false;
    }
  }
}
