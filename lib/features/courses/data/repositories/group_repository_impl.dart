import 'package:proyecto_movil/core/entities/group.dart' as raw;
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/local/hive_group_local_data_source.dart';

class GroupRepositoryImpl implements GroupRepository {
  final HiveGroupLocalDataSource local;
  GroupRepositoryImpl(this.local);

  GroupEntity _toDomain(raw.Group g) => GroupEntity(
        id: g.id,
        categoryId: g.categoryId,
        name: g.name,
        memberIds: List<String>.from(g.memberIds),
      );
  raw.Group _toRaw(GroupEntity g) => raw.Group(
        id: g.id,
        categoryId: g.categoryId,
        name: g.name,
        memberIds: List<String>.from(g.memberIds),
      );

  @override
  Future<GroupEntity> create(GroupEntity group) async {
    await local.putRaw(group.id, _toRaw(group));
    return group;
  }

  @override
  Future<void> save(GroupEntity group) async => local.putRaw(group.id, _toRaw(group));

  @override
  Future<void> delete(String id) async => local.delete(id);

  @override
  Future<List<GroupEntity>> listByCategory(String categoryId) async => local
      .listByCategory(categoryId)
      .whereType<raw.Group>()
      .map(_toDomain)
      .toList(growable: false);

  @override
  Future<void> deleteByCategory(String categoryId) async => local.deleteByCategory(categoryId);

  @override
  Future<GroupEntity?> getById(String id) async {
    final r = local.getRaw(id) as raw.Group?;
    return r == null ? null : _toDomain(r);
  }
}
