import 'package:get/get.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/use_cases/create_activity_use_case.dart';
import '../../domain/use_cases/get_activities_use_case.dart';

class ActivityController extends GetxController {
  final CreateActivityUseCase createActivityUseCase;
  final GetActivitiesUseCase getActivitiesUseCase;
  ActivityController({required this.createActivityUseCase, required this.getActivitiesUseCase});

  final activities = <ActivityModel>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final creating = false.obs;

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
}
