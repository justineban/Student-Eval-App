import '../domain/activity_entity.dart';
import '../domain/activity_repository.dart';
import 'activity_memory_datasource.dart';

/// Implementación concreta del repositorio usando un datasource en memoria.
class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityMemoryDataSource _ds = ActivityMemoryDataSource();

  @override
  Future<Activity> create(Activity activity) async {
    return _ds.create(activity);
  }

  @override
  Future<Activity?> getById(String id) async => _ds.getById(id);

  @override
  Future<List<Activity>> getByCourse(String courseId) async =>
      _ds.getByCourse(courseId);

  @override
  Future<List<Activity>> getByCategory(String categoryId) async =>
      _ds.getByCategory(categoryId);

  @override
  Future<bool> update(Activity activity) async => _ds.update(activity);

  @override
  Future<bool> delete(String id) async => _ds.delete(id);

  @override
  Future<bool> addSubmission({
    required String activityId,
    required String studentId,
  }) async => _ds.addSubmission(activityId: activityId, studentId: studentId);
}
