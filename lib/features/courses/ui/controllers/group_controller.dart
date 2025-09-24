import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/use_cases/create_group_use_case.dart';
import '../../domain/use_cases/get_groups_use_case.dart';
import '../../domain/use_cases/delete_group_use_case.dart';
import '../../domain/use_cases/add_member_to_group_use_case.dart';
import '../../domain/use_cases/remove_member_from_group_use_case.dart';
import '../../domain/use_cases/move_member_between_groups_use_case.dart';
import '../../domain/use_cases/trim_groups_to_capacity_use_case.dart';
import '../../domain/models/group_model.dart';

class CourseGroupController extends GetxController {
  final CreateCourseGroupUseCase createUseCase;
  final GetCourseGroupsUseCase listUseCase;
  final DeleteCourseGroupUseCase deleteUseCase;
  final AddMemberToGroupUseCase addMemberUseCase;
  final RemoveMemberFromGroupUseCase removeMemberUseCase;
  final MoveMemberBetweenGroupsUseCase moveMemberUseCase;
  final TrimGroupsToCapacityUseCase? trimUseCase; // optional for now
  CourseGroupController({
    required this.createUseCase,
    required this.listUseCase,
    required this.deleteUseCase,
    required this.addMemberUseCase,
    required this.removeMemberUseCase,
    required this.moveMemberUseCase,
    this.trimUseCase,
  });

  final groups = <GroupModel>[].obs;
  final loading = false.obs;
  final creating = false.obs;
  final deleting = false.obs;
  final error = RxnString();
  final expandedGroupIds = <String>{}.obs; // track which groups are expanded
  final addingMember = false.obs;
  final movingMember = false.obs;

  Future<void> load(String categoryId) async {
    loading.value = true; error.value = null;
    try { groups.assignAll(await listUseCase(categoryId)); } catch (e) { error.value = 'Error cargando grupos'; } finally { loading.value = false; }
  }

  String _autoName() => 'Grupo ${groups.length + 1}';

  Future<bool> create({required String courseId, required String categoryId}) async {
    creating.value = true; error.value = null;
    try { groups.add(await createUseCase(courseId: courseId, categoryId: categoryId, name: _autoName())); return true; } catch (e) { error.value = e.toString(); return false; } finally { creating.value = false; }
  }

  Future<bool> delete(String id) async {
    deleting.value = true; error.value = null;
    try { await deleteUseCase(id); groups.removeWhere((g) => g.id == id); return true; } catch (e) { error.value = e.toString(); return false; } finally { deleting.value = false; }
  }

  void toggleExpanded(String id) {
    if (expandedGroupIds.contains(id)) {
      expandedGroupIds.remove(id);
    } else {
      expandedGroupIds.add(id);
    }
    expandedGroupIds.refresh();
  }

  Future<GroupModel?> addMember(String groupId, String memberName) async {
    addingMember.value = true; error.value = null;
    try {
      // Enforce capacity based on category's max (not legacy g.maxMembers)
      if (!canAddToGroup(groupId)) {
        throw StateError('Este grupo alcanzó el límite de integrantes');
      }
      final updated = await addMemberUseCase(groupId: groupId, memberName: memberName);
      if (updated != null) {
        final idx = groups.indexWhere((g) => g.id == updated.id);
        if (idx != -1) groups[idx] = updated;
      }
      return updated;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      addingMember.value = false;
    }
  }

  Future<GroupModel?> removeMember(String groupId, String memberName) async {
    error.value = null;
    try {
      final updated = await removeMemberUseCase(groupId: groupId, memberName: memberName);
      if (updated != null) {
        final idx = groups.indexWhere((g) => g.id == updated.id);
        if (idx != -1) groups[idx] = updated;
      }
      return updated;
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }

  Future<(GroupModel from, GroupModel to)?> moveMember({
    required String fromGroupId,
    required String toGroupId,
    required String memberName,
  }) async {
    movingMember.value = true; error.value = null;
    try {
      final res = await moveMemberUseCase(fromGroupId: fromGroupId, toGroupId: toGroupId, memberName: memberName);
      if (res != null) {
        final (from, to) = res;
        final idxFrom = groups.indexWhere((g) => g.id == from.id);
        final idxTo = groups.indexWhere((g) => g.id == to.id);
        if (idxFrom != -1) groups[idxFrom] = from;
        if (idxTo != -1) groups[idxTo] = to;
      }
      return res;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      movingMember.value = false;
    }
  }

  bool canAddToGroup(String groupId) {
    final g = groups.firstWhereOrNull((e) => e.id == groupId);
    if (g == null) return false;
    final max = categoryMaxFor(g.categoryId);
    return g.memberIds.length < max;
  }

  int categoryMaxFor(String categoryId) {
    try {
      // Read from categories box to align with repository logic
      final box = Hive.box(HiveBoxes.categories);
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is Map && data['id'] == categoryId) {
          final max = data['maxStudentsPerGroup'];
          if (max is int) return max;
        }
      }
    } catch (_) {}
    return 5;
  }

  // Called after updating category.maxStudentsPerGroup to enforce new capacity
  Future<void> trimOverCapacityGroups(String categoryId, int newMax) async {
    try {
      final useCase = trimUseCase;
      if (useCase == null) return;
      final updated = await useCase(categoryId: categoryId, maxPerGroup: newMax);
      if (updated.isEmpty) return;
      // Merge updates into current observable list
      for (final g in updated) {
        final idx = groups.indexWhere((e) => e.id == g.id);
        if (idx != -1) {
          groups[idx] = g;
        }
      }
    } catch (e) {
      // optional: surface error
      error.value = e.toString();
    }
  }
}
