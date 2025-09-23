import 'package:get/get.dart';
import '../../domain/use_cases/create_group_use_case.dart';
import '../../domain/use_cases/get_groups_use_case.dart';
import '../../domain/use_cases/delete_group_use_case.dart';
import '../../domain/use_cases/add_member_to_group_use_case.dart';
import '../../domain/models/group_model.dart';

class CourseGroupController extends GetxController {
  final CreateCourseGroupUseCase createUseCase;
  final GetCourseGroupsUseCase listUseCase;
  final DeleteCourseGroupUseCase deleteUseCase;
  final AddMemberToGroupUseCase addMemberUseCase;
  CourseGroupController({required this.createUseCase, required this.listUseCase, required this.deleteUseCase, required this.addMemberUseCase});

  final groups = <GroupModel>[].obs;
  final loading = false.obs;
  final creating = false.obs;
  final deleting = false.obs;
  final error = RxnString();
  final expandedGroupIds = <String>{}.obs; // track which groups are expanded
  final addingMember = false.obs;

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
}
