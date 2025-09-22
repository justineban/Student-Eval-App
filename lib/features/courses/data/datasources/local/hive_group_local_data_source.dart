import 'package:hive/hive.dart';

class HiveGroupLocalDataSource {
  final Box _box;
  HiveGroupLocalDataSource(this._box);

  Iterable<dynamic> listByCategory(String categoryId) => _box.values.where((g) => g.categoryId == categoryId);
  dynamic getRaw(String id) => _box.get(id);
  Future<void> putRaw(String id, dynamic value) => _box.put(id, value);
  Future<void> delete(String id) => _box.delete(id);
  Future<void> deleteByCategory(String categoryId) async {
    final toDelete = _box.values.where((g) => g.categoryId == categoryId).toList();
    for (final g in toDelete) {
      await _box.delete(g.id);
    }
  }
}
