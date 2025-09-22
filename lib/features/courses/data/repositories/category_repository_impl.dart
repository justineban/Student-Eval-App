import 'package:proyecto_movil/core/entities/category.dart' as raw;
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/hive_category_local_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final HiveCategoryLocalDataSource local;
  CategoryRepositoryImpl(this.local);

  CategoryEntity _toDomain(raw.Category c) => CategoryEntity(
        id: c.id,
        courseId: c.courseId,
        name: c.name,
        randomAssign: c.randomAssign,
        studentsPerGroup: c.studentsPerGroup,
      );
  raw.Category _toRaw(CategoryEntity c) => raw.Category(
        id: c.id,
        courseId: c.courseId,
        name: c.name,
        randomAssign: c.randomAssign,
        studentsPerGroup: c.studentsPerGroup,
      );

  @override
  Future<CategoryEntity> create(CategoryEntity category) async {
    await local.putRaw(category.id, _toRaw(category));
    return category;
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    final r = local.getRaw(id) as raw.Category?;
    return r == null ? null : _toDomain(r);
  }

  @override
  Future<void> save(CategoryEntity category) async => local.putRaw(category.id, _toRaw(category));

  @override
  Future<void> delete(String id) async => local.delete(id);

  @override
  Future<List<CategoryEntity>> listByCourse(String courseId) async => local
      .listByCourse(courseId)
      .whereType<raw.Category>()
      .map(_toDomain)
      .toList(growable: false);
}
