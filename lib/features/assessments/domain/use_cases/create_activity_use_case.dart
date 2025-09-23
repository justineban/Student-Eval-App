import '../repositories/activity_repository.dart';
import '../repositories/category_repository.dart';
import '../models/activity_model.dart';

class CreateActivityUseCase {
  final ActivityRepository activityRepository;
  final CategoryRepository categoryRepository;
  CreateActivityUseCase({required this.activityRepository, required this.categoryRepository});

  Future<ActivityModel> call({
    required String courseId,
    required String categoryId,
    required String name,
    required String description,
    DateTime? dueDate,
    required bool visible,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Nombre requerido');
    if (description.trim().isEmpty) throw ArgumentError('Descripción requerida');
    // Validar existencia de categoría
    final cat = await categoryRepository.getCategory(categoryId);
    if (cat == null) {
      throw StateError('Debe crear antes una categoría');
    }
    return activityRepository.createActivity(
      courseId: courseId,
      categoryId: categoryId,
      name: name.trim(),
      description: description.trim(),
      dueDate: dueDate,
      visible: visible,
    );
  }
}
