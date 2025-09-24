import 'package:get/get.dart';
import '../../domain/models/assessment_model.dart';
import '../../domain/use_cases/create_assessment_use_case.dart';
import '../../domain/use_cases/get_assessment_by_activity_use_case.dart';
import '../../domain/use_cases/update_assessment_use_case.dart';
import '../../domain/use_cases/delete_assessment_by_activity_use_case.dart';

class AssessmentController extends GetxController {
  final CreateAssessmentUseCase createUseCase;
  final GetAssessmentByActivityUseCase getByActivityUseCase;
  final UpdateAssessmentUseCase updateUseCase;
  final DeleteAssessmentByActivityUseCase deleteByActivityUseCase;
  AssessmentController({required this.createUseCase, required this.getByActivityUseCase, required this.updateUseCase, required this.deleteByActivityUseCase});

  final current = Rxn<AssessmentModel>();
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();

  Future<void> loadForActivity(String activityId) async {
    loading.value = true; error.value = null;
    try {
      current.value = await getByActivityUseCase(activityId);
    } catch (e) {
      error.value = 'Error cargando evaluación';
    } finally {
      loading.value = false;
    }
  }

  Future<AssessmentModel?> create({
    required String courseId,
    required String activityId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    required bool gradesVisible,
  }) async {
    saving.value = true; error.value = null;
    try {
      final a = await createUseCase(
        courseId: courseId,
        activityId: activityId,
        title: title,
        durationMinutes: durationMinutes,
        startAt: startAt,
        gradesVisible: gradesVisible,
      );
      current.value = a;
      return a;
    } catch (e) {
      error.value = 'No se pudo crear la evaluación';
      return null;
    } finally {
      saving.value = false;
    }
  }

  Future<void> toggleGradesVisibility() async {
    final a = current.value; if (a == null) return;
    a.gradesVisible = !a.gradesVisible;
    current.value = await updateUseCase(a);
  }

  Future<void> updateMeta({String? title, int? durationMinutes}) async {
    final a = current.value; if (a == null) return;
    if (title != null) a.title = title;
    if (durationMinutes != null) a.durationMinutes = durationMinutes;
    current.value = await updateUseCase(a);
  }

  Future<void> cancel() async {
    final a = current.value; if (a == null) return;
    try {
      error.value = null;
      await deleteByActivityUseCase(a.activityId);
      current.value = null;
    } catch (e) {
      error.value = 'No se pudo cancelar la evaluación';
      rethrow;
    }
  }

  Future<void> deleteForActivity(String activityId) async {
    await deleteByActivityUseCase(activityId);
    current.value = null;
  }
}
