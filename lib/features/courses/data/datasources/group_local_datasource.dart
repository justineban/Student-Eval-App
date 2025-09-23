import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/group_model.dart';

abstract class CourseGroupLocalDataSource {
  Future<GroupModel> save(GroupModel group);
  Future<List<GroupModel>> fetchByCategory(String categoryId);
  Future<void> delete(String id);
  Future<GroupModel?> fetchById(String id);
}

class HiveCourseGroupLocalDataSource implements CourseGroupLocalDataSource {
  late final Box _box;
  HiveCourseGroupLocalDataSource({Box? box}) { _box = box ?? Hive.box(HiveBoxes.groups); }

  @override
  Future<GroupModel> save(GroupModel group) async {
    await _box.put(group.id, {
      'id': group.id,
      'courseId': group.courseId,
      'categoryId': group.categoryId,
      'name': group.name,
      'memberIds': group.memberIds,
    });
    return group;
  }

  @override
  Future<List<GroupModel>> fetchByCategory(String categoryId) async {
    final result = <GroupModel>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data is Map && data['categoryId'] == categoryId) {
        result.add(_fromMap(data));
      }
    }
    return result;
  }

  @override
  Future<void> delete(String id) async => _box.delete(id);

  @override
  Future<GroupModel?> fetchById(String id) async {
    final data = _box.get(id);
    if (data is Map) return _fromMap(data);
    return null;
  }

  GroupModel _fromMap(Map map) => GroupModel(
        id: map['id'] as String,
        courseId: map['courseId'] as String,
        categoryId: map['categoryId'] as String,
        name: map['name'] as String,
        memberIds: (map['memberIds'] as List?)?.cast<String>() ?? [],
      );
}
