import 'activity_entity.dart';

/// Contrato del repositorio de Activities (dominio)
abstract class ActivityRepository {
  Future<Activity> create(Activity activity);
  Future<Activity?> getById(String id);
  Future<List<Activity>> getByCourse(String courseId);
  Future<List<Activity>> getByCategory(String categoryId);
  Future<bool> update(Activity activity);
  Future<bool> delete(String id);
  Future<bool> addSubmission({
    required String activityId,
    required String studentId,
  });
}
