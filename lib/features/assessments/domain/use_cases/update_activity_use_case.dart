import '../repositories/activity_repository.dart';
import '../models/activity_model.dart';

class UpdateActivityUseCase {
  final ActivityRepository repository;
  UpdateActivityUseCase(this.repository);

  Future<ActivityModel> call({
    required String id,
    required String courseId,
    required String categoryId,
    required String name,
    required String description,
    DateTime? dueDate,
    required bool visible,
  }) {
    return repository.updateActivity(
      id: id,
      courseId: courseId,
      categoryId: categoryId,
      name: name,
      description: description,
      dueDate: dueDate,
      visible: visible,
    );
  }
}
