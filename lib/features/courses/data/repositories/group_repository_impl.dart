import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/group_model.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_local_datasource.dart';

class CourseGroupRepositoryImpl implements CourseGroupRepository {
  final CourseGroupLocalDataSource local;
  final _uuid = const Uuid();
  CourseGroupRepositoryImpl({required this.local});

  @override
  Future<GroupModel> create({required String courseId, required String categoryId, required String name}) async {
    final g = GroupModel(id: _uuid.v4(), courseId: courseId, categoryId: categoryId, name: name);
    return await local.save(g);
  }

  @override
  Future<List<GroupModel>> listByCategory(String categoryId) => local.fetchByCategory(categoryId);
  
  @override
  Future<GroupModel?> addMember({required String groupId, required String memberName}) async {
    final existing = await local.fetchById(groupId);
    if (existing == null) return null;
    final max = _getCategoryMax(existing.categoryId);
    if (existing.memberIds.length >= max) {
      throw StateError('El grupo alcanzó el límite de integrantes');
    }
    final updated = GroupModel(
      id: existing.id,
      courseId: existing.courseId,
      categoryId: existing.categoryId,
      name: existing.name,
      memberIds: [...existing.memberIds, memberName],
    );
    await local.save(updated);
    return updated;
  }

  @override
  Future<void> delete(String id) => local.delete(id);

  @override
  Future<GroupModel?> removeMember({required String groupId, required String memberName}) async {
    final existing = await local.fetchById(groupId);
    if (existing == null) return null;
    final updated = GroupModel(
      id: existing.id,
      courseId: existing.courseId,
      categoryId: existing.categoryId,
      name: existing.name,
      memberIds: [...existing.memberIds]..remove(memberName),
    );
    await local.save(updated);
    return updated;
  }

  @override
  Future<(GroupModel from, GroupModel to)?> moveMember({
    required String fromGroupId,
    required String toGroupId,
    required String memberName,
  }) async {
    final from = await local.fetchById(fromGroupId);
    final to = await local.fetchById(toGroupId);
    if (from == null || to == null) return null;
    final max = _getCategoryMax(to.categoryId);
    if (to.memberIds.length >= max) {
      throw StateError('El grupo destino alcanzó el límite de integrantes');
    }
    if (!from.memberIds.contains(memberName)) return null;

    final updatedFrom = GroupModel(
      id: from.id,
      courseId: from.courseId,
      categoryId: from.categoryId,
      name: from.name,
      memberIds: [...from.memberIds]..remove(memberName),
    );
    final updatedTo = GroupModel(
      id: to.id,
      courseId: to.courseId,
      categoryId: to.categoryId,
      name: to.name,
      memberIds: [...to.memberIds, memberName],
    );
    await local.save(updatedFrom);
    await local.save(updatedTo);
    return (updatedFrom, updatedTo);
  }

  int _getCategoryMax(String categoryId) {
    try {
      final box = Hive.box(HiveBoxes.categories);
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is Map && data['id'] == categoryId) {
          final max = data['maxStudentsPerGroup'];
          if (max is int) return max;
        }
      }
    } catch (_) {}
    return 5; // fallback
  }

  @override
  Future<List<GroupModel>> trimGroupsToCapacity({required String categoryId, required int maxPerGroup}) async {
    final groups = await local.fetchByCategory(categoryId);
    final updatedGroups = <GroupModel>[];
    for (final g in groups) {
      if (g.memberIds.length > maxPerGroup) {
        final trimmedMembers = g.memberIds.take(maxPerGroup).toList();
        final updated = GroupModel(
          id: g.id,
          courseId: g.courseId,
          categoryId: g.categoryId,
          name: g.name,
          memberIds: trimmedMembers,
        );
        await local.save(updated);
        updatedGroups.add(updated);
      }
    }
    return updatedGroups;
  }
}
