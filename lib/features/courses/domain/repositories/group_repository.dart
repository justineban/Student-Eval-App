import '../entities/group.dart';

abstract class GroupRepository {
  Future<GroupEntity> create(GroupEntity group);
  Future<void> save(GroupEntity group);
  Future<void> delete(String id);
  Future<List<GroupEntity>> listByCategory(String categoryId);
  Future<void> deleteByCategory(String categoryId);
  Future<GroupEntity?> getById(String id);
}
