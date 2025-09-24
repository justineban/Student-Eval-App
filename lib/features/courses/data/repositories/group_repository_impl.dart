import 'package:uuid/uuid.dart';
import '../../domain/models/group_model.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_remote_roble_datasource.dart';
import '../datasources/group_local_datasource.dart';

class CourseGroupRepositoryImpl implements CourseGroupRepository {
  final CourseGroupRemoteDataSource remote;
  final CourseGroupLocalDataSource? localCache; // optional cache mirror
  final _uuid = const Uuid();
  CourseGroupRepositoryImpl({required this.remote, this.localCache});

  @override
  Future<GroupModel> create({required String courseId, required String categoryId, required String name}) async {
    final id = _uuid.v4();
    final created = await remote.createGroup(id: id, courseId: courseId, categoryId: categoryId, name: name);
    try { await localCache?.save(created); } catch (_) {}
    return created;
  }

  @override
  Future<List<GroupModel>> listByCategory(String categoryId) async {
    final list = await remote.listByCategory(categoryId);
    if (localCache != null) {
      for (final g in list) { try { await localCache!.save(g); } catch (_) {} }
    }
    return list;
  }
  
  @override
  Future<GroupModel?> addMember({required String groupId, required String memberName}) async {
    final existing = await remote.fetchById(groupId);
    if (existing == null) return null;
    final max = await _getCategoryMax(existing.categoryId);
    if (existing.memberIds.length >= max) {
      throw StateError('El grupo alcanzó el límite de integrantes');
    }
    final updatedMembers = [...existing.memberIds, memberName];
    final updated = await remote.updateGroup(id: groupId, updates: {'memberIds': updatedMembers});
    try { await localCache?.save(updated); } catch (_) {}
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await remote.deleteGroup(id);
    try { await localCache?.delete(id); } catch (_) {}
  }

  @override
  Future<GroupModel?> removeMember({required String groupId, required String memberName}) async {
    final existing = await remote.fetchById(groupId);
    if (existing == null) return null;
    final updatedMembers = [...existing.memberIds]..remove(memberName);
    final updated = await remote.updateGroup(id: groupId, updates: {'memberIds': updatedMembers});
    return updated;
  }

  @override
  Future<(GroupModel from, GroupModel to)?> moveMember({
    required String fromGroupId,
    required String toGroupId,
    required String memberName,
  }) async {
    final from = await remote.fetchById(fromGroupId);
    final to = await remote.fetchById(toGroupId);
    if (from == null || to == null) return null;
    final max = await _getCategoryMax(to.categoryId);
    if (to.memberIds.length >= max) {
      throw StateError('El grupo destino alcanzó el límite de integrantes');
    }
    if (!from.memberIds.contains(memberName)) return null;
    final updatedFromMembers = [...from.memberIds]..remove(memberName);
    final updatedToMembers = [...to.memberIds, memberName];
    final newFrom = await remote.updateGroup(id: from.id, updates: {'memberIds': updatedFromMembers});
    final newTo = await remote.updateGroup(id: to.id, updates: {'memberIds': updatedToMembers});
    try { await localCache?.save(newFrom); await localCache?.save(newTo); } catch (_) {}
    return (newFrom, newTo);
  }

  Future<int> _getCategoryMax(String categoryId) async {
    // Fetch category remotely to get maxStudentsPerGroup
    // We avoid importing the whole category remote here; assume server enforces too.
    // As a safe default if not retrievable, return 5.
    try {
      // Lightweight approach: rely on an environment where category is also in remote DB.
      // This function could be replaced by a dedicated CategoryRemoteDataSource call.
      // For now, just return a sane default; UI should also validate limits.
      return 5;
    } catch (_) {
      return 5;
    }
  }

  @override
  Future<List<GroupModel>> trimGroupsToCapacity({required String categoryId, required int maxPerGroup}) async {
    final groups = await remote.listByCategory(categoryId);
    final updatedGroups = <GroupModel>[];
    for (final g in groups) {
      if (g.memberIds.length > maxPerGroup) {
        final trimmedMembers = g.memberIds.take(maxPerGroup).toList();
        final updated = await remote.updateGroup(id: g.id, updates: {'memberIds': trimmedMembers});
        try { await localCache?.save(updated); } catch (_) {}
        updatedGroups.add(updated);
      }
    }
    return updatedGroups;
  }
}
