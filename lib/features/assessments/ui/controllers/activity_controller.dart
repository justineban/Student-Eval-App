import 'package:get/get.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/use_cases/create_activity_use_case.dart';
import '../../domain/use_cases/get_activities_use_case.dart';
import '../../domain/use_cases/update_activity_use_case.dart';
import '../../domain/use_cases/delete_activity_use_case.dart';

class ActivityController extends GetxController {
  final CreateActivityUseCase createActivityUseCase;
  final GetActivitiesUseCase getActivitiesUseCase;
  final UpdateActivityUseCase updateActivityUseCase;
  final DeleteActivityUseCase deleteActivityUseCase;
  ActivityController({
    required this.createActivityUseCase,
    required this.getActivitiesUseCase,
    required this.updateActivityUseCase,
    required this.deleteActivityUseCase,
  });

  final activities = <ActivityModel>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final creating = false.obs;
  final updating = false.obs;
  final deleting = false.obs;

  Future<void> load(String courseId) async {
    loading.value = true;
    error.value = null;
    try {
      final list = await getActivitiesUseCase(courseId);
      activities.assignAll(list);
    } catch (e) {
      error.value = 'Error cargando actividades';
    } finally {
      loading.value = false;
    }
  }

  Future<ActivityModel?> create({
    required String courseId,
    required String categoryId,
    required String name,
    required String description,
    DateTime? dueDate,
    required bool visible,
  }) async {
    creating.value = true;
    error.value = null;
    try {
      final act = await createActivityUseCase(
        courseId: courseId,
        categoryId: categoryId,
        name: name,
        description: description,
        dueDate: dueDate,
        visible: visible,
      );
      activities.add(act);
      return act;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      creating.value = false;
    }
  }

  Future<ActivityModel?> updateActivity(ActivityModel activity) async {
    updating.value = true; error.value = null;
    try {
      final updated = await updateActivityUseCase.call(
        id: activity.id,
        courseId: activity.courseId,
        categoryId: activity.categoryId,
        name: activity.name,
        description: activity.description,
        dueDate: activity.dueDate,
        visible: activity.visible,
      );
      final idx = activities.indexWhere((e) => e.id == activity.id);
      if (idx != -1) activities[idx] = updated;
      return updated;
    } catch (e) {
      error.value = 'Error actualizando actividad';
      return null;
    } finally {
      updating.value = false;
    }
  }

  Future<bool> delete(String id) async {
    deleting.value = true; error.value = null;
    try {
      await deleteActivityUseCase.call(id);
      activities.removeWhere((e) => e.id == id);
      return true;
    } catch (e) {
      error.value = 'Error eliminando actividad';
      return false;
    } finally {
      deleting.value = false;
    }
  }

  Future<void> toggleVisibility(ActivityModel a) async {
    a.visible = !a.visible;
    await updateActivity(a);
  }
}
