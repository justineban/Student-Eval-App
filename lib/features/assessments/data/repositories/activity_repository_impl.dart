import 'package:uuid/uuid.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_local_datasource.dart';
import '../datasources/activity_remote_roble_datasource.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remote;
  final ActivityLocalDataSource? localCache;
  final _uuid = const Uuid();
  ActivityRepositoryImpl({required this.remote, this.localCache});

  @override
  Future<ActivityModel> createActivity({required String courseId, required String categoryId, required String name, required String description, DateTime? dueDate, required bool visible}) async {
    final id = _uuid.v4();
    final created = await remote.create(
      id: id,
      courseId: courseId,
      categoryId: categoryId,
      name: name,
      description: description,
      dueDate: dueDate,
      visible: visible,
    );
    if (localCache != null) {
      await localCache!.save(created);
    }
    return created;
  }

  @override
  Future<List<ActivityModel>> getActivitiesByCourse(String courseId) async {
    final list = await remote.listByCourse(courseId);
    if (localCache != null) {
      // mirror to cache for quick subsequent loads
      for (final a in list) {
        await localCache!.save(a);
      }
    }
    return list;
  }

  @override
  Future<ActivityModel> updateActivity({
    required String id,
    required String courseId,
    required String categoryId,
    required String name,
    required String description,
    DateTime? dueDate,
    required bool visible,
  }) async {
    final updated = await remote.update(id: id, updates: {
      'courseId': courseId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'dueDate': dueDate,
      'visible': visible,
    });
    if (localCache != null) {
      await localCache!.update(updated);
    }
    return updated;
  }

  @override
  Future<void> deleteActivity(String id) async {
    await remote.delete(id);
    if (localCache != null) {
      await localCache!.delete(id);
    }
  }
}
