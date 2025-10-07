import 'package:get/get.dart';
import 'dart:math';
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
    loading.value = true;
    error.value = null;
    try {
      groups.assignAll(await listUseCase(categoryId));
    } catch (e) {
      error.value = 'Error cargando grupos';
    } finally {
      loading.value = false;
    }
  }

  String _autoName() => 'Grupo ${groups.length + 1}';

  Future<bool> create({
    required String courseId,
    required String categoryId,
  }) async {
    creating.value = true;
    error.value = null;
    try {
      groups.add(
        await createUseCase(
          courseId: courseId,
          categoryId: categoryId,
          name: _autoName(),
        ),
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      creating.value = false;
    }
  }

  Future<bool> delete(String id) async {
    deleting.value = true;
    error.value = null;
    try {
      await deleteUseCase(id);
      groups.removeWhere((g) => g.id == id);
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      deleting.value = false;
    }
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
    addingMember.value = true;
    error.value = null;
    try {
      // Enforce capacity based on category's max (not legacy g.maxMembers)
      if (!canAddToGroup(groupId)) {
        throw StateError('Este grupo alcanzó el límite de integrantes');
      }
      final updated = await addMemberUseCase(
        groupId: groupId,
        memberName: memberName,
      );
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
      final updated = await removeMemberUseCase(
        groupId: groupId,
        memberName: memberName,
      );
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
    movingMember.value = true;
    error.value = null;
    try {
      final res = await moveMemberUseCase(
        fromGroupId: fromGroupId,
        toGroupId: toGroupId,
        memberName: memberName,
      );
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
      final updated = await useCase(
        categoryId: categoryId,
        maxPerGroup: newMax,
      );
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

  // Compute and create enough groups so capacity >= number of students. Does not modify existing groups.
  Future<void> ensureMinimumGroupsForCategory({
    required String courseId,
    required String categoryId,
    required int maxPerGroup,
  }) async {
    // Count students in course
    int studentsCount = 0;
    try {
      final box = Hive.box(HiveBoxes.courses);
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is Map && data['id'] == courseId) {
          studentsCount = ((data['studentIds'] as List?)?.length) ?? 0;
          break;
        }
      }
    } catch (_) {}
    if (studentsCount <= 0 || maxPerGroup <= 0) return;

    // Current groups count for this category
    final existing = await listUseCase(categoryId);
    final desired = (studentsCount / maxPerGroup).ceil().clamp(1, 1 << 31);
    final toCreate = desired - existing.length;
    if (toCreate <= 0) return;

    // Create additional groups without touching existing ones
    for (int i = 0; i < toCreate; i++) {
      await createUseCase(
        courseId: courseId,
        categoryId: categoryId,
        name: 'Grupo ${existing.length + i + 1}',
      );
    }
    // Refresh local state if this controller is currently showing the same category
    if (groups.isNotEmpty && groups.first.categoryId == categoryId) {
      await load(categoryId);
    }
  }

  // Randomly distribute all course students across existing groups for a category. Ensures enough groups first.
  Future<void> randomDistributeAllStudents({
    required String courseId,
    required String categoryId,
    required int maxPerGroup,
  }) async {
    // Ensure enough groups
    await ensureMinimumGroupsForCategory(
      courseId: courseId,
      categoryId: categoryId,
      maxPerGroup: maxPerGroup,
    );
    // Load fresh groups for this category
    var catGroups = await listUseCase(categoryId);
    if (catGroups.isEmpty) return;
    // Load students of course
    List<String> students = [];
    try {
      final box = Hive.box(HiveBoxes.courses);
      for (final key in box.keys) {
        final data = box.get(key);
        if (data is Map && data['id'] == courseId) {
          students =
              (data['studentIds'] as List?)?.cast<String>() ?? <String>[];
          break;
        }
      }
    } catch (_) {}
    if (students.isEmpty) return;

    // Determine desired number of groups and enforce exact count (delete extras / create missing)
    final desired = (students.length / maxPerGroup).ceil().clamp(1, 1 << 31);
    if (catGroups.length > desired) {
      // Prefer removing the extra groups at the end of the list
      final extras = catGroups.sublist(desired);
      for (final g in extras) {
        await deleteUseCase(g.id);
      }
    } else if (catGroups.length < desired) {
      final toCreate = desired - catGroups.length;
      for (int i = 0; i < toCreate; i++) {
        await createUseCase(
          courseId: courseId,
          categoryId: categoryId,
          name: 'Grupo ${catGroups.length + i + 1}',
        );
      }
    }
    // Reload groups after structural changes
    catGroups = await listUseCase(categoryId);

    // Shuffle to randomize initial order
    students.shuffle(Random());
    final n = catGroups.length;
    final totalCapacity = n * maxPerGroup;
    if (students.length > totalCapacity) {
      // As a safeguard, ensure again (shouldn't happen after enforcing desired)
      final extraNeeded = ((students.length - totalCapacity) / maxPerGroup)
          .ceil();
      for (int i = 0; i < extraNeeded; i++) {
        await createUseCase(
          courseId: courseId,
          categoryId: categoryId,
          name: 'Grupo ${catGroups.length + i + 1}',
        );
      }
      // Reload again to include new groups
      catGroups = await listUseCase(categoryId);
    }

    // Capacity-aware round-robin placement
    final partitions = List.generate(n, (_) => <String>[]);
    int pointer = 0;
    for (final s in students) {
      // advance pointer until we find a group with capacity
      int attempts = 0;
      while (attempts < n && partitions[pointer].length >= maxPerGroup) {
        pointer = (pointer + 1) % n;
        attempts++;
      }
      partitions[pointer].add(s);
      pointer = (pointer + 1) % n;
    }

    // Persist by reconciling remote membership via use cases (remove extras, then move/add missing)
    // Build initial membership map: studentId -> currentGroupId
    final currentMembership = <String, String>{};
    for (final g in catGroups) {
      for (final m in g.memberIds) {
        currentMembership[m] = g.id;
      }
    }

    // Remove extras first to free capacity
    for (int i = 0; i < n; i++) {
      final g = catGroups[i];
      final target = partitions[i].toSet();
      final current = g.memberIds.toSet();
      final extras = current.difference(target);
      for (final m in extras) {
        try {
          await removeMemberUseCase(groupId: g.id, memberName: m);
          if (currentMembership[m] == g.id) currentMembership.remove(m);
        } catch (_) {}
      }
    }

    // Add or move missing members into their target groups
    final validGroupIds = catGroups.map((g) => g.id).toSet();
    for (int i = 0; i < n; i++) {
      final g = catGroups[i];
      final target = partitions[i].toSet();
      final current = g.memberIds.toSet();
      final missing = target.difference(current);
      for (final m in missing) {
        final fromGroupId = currentMembership[m];
        try {
          if (fromGroupId == null || !validGroupIds.contains(fromGroupId)) {
            // Not in any group yet: add directly
            await addMemberUseCase(groupId: g.id, memberName: m);
          } else if (fromGroupId != g.id) {
            // Move from previous group
            final res = await moveMemberUseCase(
              fromGroupId: fromGroupId,
              toGroupId: g.id,
              memberName: m,
            );
            // Update map based on successful move
            if (res != null) currentMembership[m] = g.id;
          }
        } catch (_) {
          // Best-effort; continue assigning others
        }
      }
    }

    // Refresh local if applicable
    if (groups.isNotEmpty && groups.first.categoryId == categoryId) {
      await load(categoryId);
    }
  }

  // Handle a new student joining the course: ensure enough groups and place into a random category's group if applicable
  Future<void> handleStudentJoinedCourse({
    required String courseId,
    required String studentId,
  }) async {
    // Iterate categories in this course
    try {
      final cbox = Hive.box(HiveBoxes.categories);
      for (final key in cbox.keys) {
        final data = cbox.get(key);
        if (data is Map && data['courseId'] == courseId) {
          final categoryId = data['id'] as String;
          final max = data['maxStudentsPerGroup'] as int? ?? 5;
          final isRandom = data['randomGroups'] as bool? ?? false;
          // Ensure enough capacity (may create new groups)
          await ensureMinimumGroupsForCategory(
            courseId: courseId,
            categoryId: categoryId,
            maxPerGroup: max,
          );
          if (isRandom) {
            // Assign student to any group with capacity if not already assigned under this category
            final catGroups = await listUseCase(categoryId);
            final already = catGroups.any(
              (g) => g.memberIds.contains(studentId),
            );
            if (already) continue;
            final target = catGroups.firstWhereOrNull(
              (g) => g.memberIds.length < max,
            );
            if (target != null) {
              await addMemberUseCase(groupId: target.id, memberName: studentId);
            }
          }
        }
      }
    } catch (_) {}
  }
}
