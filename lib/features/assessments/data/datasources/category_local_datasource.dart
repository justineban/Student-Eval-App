import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<CategoryModel> save(CategoryModel category);
  Future<List<CategoryModel>> fetchByCourse(String courseId);
  Future<CategoryModel?> fetchById(String id);
  Future<void> delete(String id);
}

class HiveCategoryLocalDataSource implements CategoryLocalDataSource {
  late final Box _box;
  HiveCategoryLocalDataSource({Box? box}) {
    _box = box ?? Hive.box(HiveBoxes.categories);
  }
  @override
  Future<CategoryModel> save(CategoryModel category) async {
    await _box.put(category.id, {
      'id': category.id,
      'courseId': category.courseId,
      'name': category.name,
      'randomGroups': category.randomGroups,
      'maxStudentsPerGroup': category.maxStudentsPerGroup,
    });
    return category;
  }

  @override
  Future<List<CategoryModel>> fetchByCourse(String courseId) async {
    final List<CategoryModel> result = [];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data is Map && data['courseId'] == courseId) {
        result.add(_fromMap(data));
      }
    }
    return result;
  }

  @override
  Future<CategoryModel?> fetchById(String id) async {
    final data = _box.get(id);
    if (data is Map) return _fromMap(data);
    return null;
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  CategoryModel _fromMap(Map map) => CategoryModel(
        id: map['id'] as String,
        courseId: map['courseId'] as String,
        name: map['name'] as String,
        randomGroups: map['randomGroups'] as bool,
        maxStudentsPerGroup: map['maxStudentsPerGroup'] as int,
      );
}
