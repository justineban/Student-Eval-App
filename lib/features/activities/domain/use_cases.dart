import 'activity_entity.dart';
import 'activity_repository.dart';

/// Use cases básicos para Activities. Cada clase mantiene single responsibility.

class CreateActivityUseCase {
  final ActivityRepository repository;
  CreateActivityUseCase(this.repository);
  Future<Activity> call(Activity activity) => repository.create(activity);
}

class GetActivityByIdUseCase {
  final ActivityRepository repository;
  GetActivityByIdUseCase(this.repository);
  Future<Activity?> call(String id) => repository.getById(id);
}

class GetActivitiesByCourseUseCase {
  final ActivityRepository repository;
  GetActivitiesByCourseUseCase(this.repository);
  Future<List<Activity>> call(String courseId) =>
      repository.getByCourse(courseId);
}

class GetActivitiesByCategoryUseCase {
  final ActivityRepository repository;
  GetActivitiesByCategoryUseCase(this.repository);
  Future<List<Activity>> call(String categoryId) =>
      repository.getByCategory(categoryId);
}

class UpdateActivityUseCase {
  final ActivityRepository repository;
  UpdateActivityUseCase(this.repository);
  Future<bool> call(Activity activity) => repository.update(activity);
}

class DeleteActivityUseCase {
  final ActivityRepository repository;
  DeleteActivityUseCase(this.repository);
  Future<bool> call(String id) => repository.delete(id);
}

class AddSubmissionUseCase {
  final ActivityRepository repository;
  AddSubmissionUseCase(this.repository);
  Future<bool> call({required String activityId, required String studentId}) =>
      repository.addSubmission(activityId: activityId, studentId: studentId);
}
