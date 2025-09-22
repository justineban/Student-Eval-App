import 'package:hive/hive.dart';

class HiveCategoryLocalDataSource {
  final Box _box;
  HiveCategoryLocalDataSource(this._box);

  Iterable<dynamic> getAllRaw() => _box.values;
  dynamic getRaw(String id) => _box.get(id);
  Future<void> putRaw(String id, dynamic value) => _box.put(id, value);
  Future<void> delete(String id) => _box.delete(id);
  Iterable<dynamic> listByCourse(String courseId) => _box.values.where((c) => c.courseId == courseId);
}
