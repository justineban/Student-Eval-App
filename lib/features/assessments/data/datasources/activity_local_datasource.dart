import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/activity_model.dart';

abstract class ActivityLocalDataSource {
  Future<ActivityModel> save(ActivityModel activity);
  Future<List<ActivityModel>> fetchByCourse(String courseId);
  Future<ActivityModel> update(ActivityModel activity);
  Future<void> delete(String id);
}

class HiveActivityLocalDataSource implements ActivityLocalDataSource {
  late final Box _box;
  HiveActivityLocalDataSource({Box? box}) {
    _box = box ?? Hive.box(HiveBoxes.activities);
  }

  @override
  Future<ActivityModel> save(ActivityModel activity) async {
    await _box.put(activity.id, {
      'id': activity.id,
      'courseId': activity.courseId,
      'categoryId': activity.categoryId,
      'name': activity.name,
      'description': activity.description,
      'dueDate': activity.dueDate?.toIso8601String(),
      'visible': activity.visible,
    });
    return activity;
  }

  @override
  Future<List<ActivityModel>> fetchByCourse(String courseId) async {
    final List<ActivityModel> result = [];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data is Map && data['courseId'] == courseId) {
        result.add(_fromMap(data));
      }
    }
    return result;
  }

  @override
  Future<ActivityModel> update(ActivityModel activity) async {
    // For Hive, update is same as put with same key
    await _box.put(activity.id, {
      'id': activity.id,
      'courseId': activity.courseId,
      'categoryId': activity.categoryId,
      'name': activity.name,
      'description': activity.description,
      'dueDate': activity.dueDate?.toIso8601String(),
      'visible': activity.visible,
    });
    return activity;
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  ActivityModel _fromMap(Map map) => ActivityModel(
        id: map['id'] as String,
        courseId: map['courseId'] as String,
        categoryId: map['categoryId'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
        visible: map['visible'] as bool,
      );
}
