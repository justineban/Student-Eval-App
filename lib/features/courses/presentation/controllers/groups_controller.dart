import 'package:get/get.dart';

import '../../domain/entities/group.dart';
import '../../domain/use_cases/list_groups_for_category.dart';
import '../../domain/use_cases/join_group.dart';
import '../../domain/use_cases/leave_group.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class GroupsController extends GetxController {
  final ListGroupsForCategoryUseCase listGroups;
  final JoinGroupUseCase joinGroup;
  final LeaveGroupUseCase leaveGroup;

  GroupsController({
    required this.listGroups,
    required this.joinGroup,
    required this.leaveGroup,
  });

  final RxList<GroupEntity> groups = <GroupEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  String? _categoryId;

  AuthController get auth => Get.find<AuthController>();

  Future<void> load(String categoryId) async {
    _categoryId = categoryId;
    isLoading.value = true; error.value = null;
    try {
      groups.value = await listGroups(categoryId);
    } catch (e) { error.value = e.toString(); } finally { isLoading.value = false; }
  }

  Future<GroupEntity?> join(String groupId, {int? capacity}) async {
    final userId = auth.currentUserId.value;
    if (userId == null) {
      return null;
    }
    try {
      final updated = await joinGroup(groupId: groupId, userId: userId, capacity: capacity);
      if (updated != null) {
        final idx = groups.indexWhere((g) => g.id == groupId);
        if (idx != -1) {
          groups[idx] = updated;
        } else {
          groups.add(updated);
        }
      }
      return updated;
    } catch (e) { error.value = e.toString(); return null; }
  }

  Future<GroupEntity?> leave(String groupId) async {
    final userId = auth.currentUserId.value;
    if (userId == null) {
      return null;
    }
    try {
      final updated = await leaveGroup(groupId: groupId, userId: userId);
      if (updated != null) {
        final idx = groups.indexWhere((g) => g.id == groupId);
        if (idx != -1) {
          groups[idx] = updated;
        } else {
          groups.add(updated);
        }
      }
      return updated;
    } catch (e) { error.value = e.toString(); return null; }
  }

  @override
  Future<void> refresh() async {
    final id = _categoryId;
    if (id != null) {
      await load(id);
    }
  }
}
