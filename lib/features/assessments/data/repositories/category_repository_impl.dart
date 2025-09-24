import 'package:uuid/uuid.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_roble_datasource.dart';
import '../datasources/category_local_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remote;
  final CategoryLocalDataSource? localCache; // optional: mirror data in Hive
  final _uuid = const Uuid();
  CategoryRepositoryImpl({required this.remote, this.localCache});

  @override
  Future<CategoryModel> createCategory({required String courseId, required String name, required bool randomGroups, required int maxStudentsPerGroup}) async {
    final id = _uuid.v4();
    final created = await remote.create(id: id, courseId: courseId, name: name, randomGroups: randomGroups, maxStudentsPerGroup: maxStudentsPerGroup);
    // Mirror to local cache if available
    try { await localCache?.save(created); } catch (_) {}
    return created;
  }

  @override
  Future<List<CategoryModel>> getCategoriesByCourse(String courseId) async {
    final list = await remote.listByCourse(courseId);
    // Optionally refresh cache
    if (localCache != null) {
      for (final c in list) { try { await localCache!.save(c); } catch (_) {} }
    }
    return list;
  }

  @override
  Future<CategoryModel?> getCategory(String id) async {
    final c = await remote.fetchById(id);
    if (c != null) { try { await localCache?.save(c); } catch (_) {} }
    return c;
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final updated = await remote.update(id: category.id, updates: {
      'courseId': category.courseId,
      'name': category.name,
      'randomGroups': category.randomGroups,
      'maxStudentsPerGroup': category.maxStudentsPerGroup,
    });
    try { await localCache?.save(updated); } catch (_) {}
    return updated;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await remote.delete(id);
    try { await localCache?.delete(id); } catch (_) {}
  }
}
