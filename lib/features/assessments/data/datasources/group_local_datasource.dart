import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/group_model.dart';

abstract class GroupLocalDataSource {
  Future<GroupModel> save(GroupModel group);
  Future<List<GroupModel>> fetchByCategory(String categoryId);
  Future<void> delete(String id);
}

class HiveGroupLocalDataSource implements GroupLocalDataSource {
  late final Box _box;
  HiveGroupLocalDataSource({Box? box}) {
    _box = box ?? Hive.box(HiveBoxes.groups);
  }
  @override
  Future<GroupModel> save(GroupModel group) async {
    await _box.put(group.id, {
      'id': group.id,
      'categoryId': group.categoryId,
      'courseId': group.courseId,
      'name': group.name,
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

  GroupModel _fromMap(Map map) => GroupModel(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String,
        courseId: map['courseId'] as String,
        name: map['name'] as String,
      );
}
