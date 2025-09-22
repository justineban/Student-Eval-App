import 'package:hive/hive.dart';

/// Raw local persistence for courses (Hive). No business logic or mapping.
class HiveCourseLocalDataSource {
  final Box _box; // underlying Hive box (stores raw model / adapter object)
  HiveCourseLocalDataSource(this._box);

  Iterable<dynamic> getAllRaw() => _box.values;
  dynamic getRaw(String id) => _box.get(id);
  Future<void> putRaw(String id, dynamic value) => _box.put(id, value);
  Future<void> delete(String id) => _box.delete(id);
}
