import 'package:get/get.dart';
import '../../domain/models/group_model.dart';
import '../../domain/use_cases/create_group_use_case.dart';
import '../../domain/use_cases/get_groups_use_case.dart';
import '../../domain/use_cases/delete_group_use_case.dart';

class GroupController extends GetxController {
  final CreateGroupUseCase createGroupUseCase;
  final GetGroupsUseCase getGroupsUseCase;
  final DeleteGroupUseCase deleteGroupUseCase;
  GroupController({required this.createGroupUseCase, required this.getGroupsUseCase, required this.deleteGroupUseCase});

  final groups = <GroupModel>[].obs;
  final loading = false.obs;
  final creating = false.obs;
  final deleting = false.obs;
  final error = RxnString();

  Future<void> load(String categoryId) async {
    loading.value = true;
    error.value = null;
    try {
      final list = await getGroupsUseCase(categoryId);
      groups.assignAll(list);
    } catch (e) {
      error.value = 'Error cargando grupos';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> create({required String courseId, required String categoryId, required String name}) async {
    creating.value = true;
    error.value = null;
    try {
      final g = await createGroupUseCase(courseId: courseId, categoryId: categoryId, name: name);
      groups.add(g);
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
      await deleteGroupUseCase(id);
      groups.removeWhere((g) => g.id == id);
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      deleting.value = false;
    }
  }
}
