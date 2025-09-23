import 'assessment_entity.dart';
import 'assessment_repository.dart';

class LaunchAssessmentUseCase {
  final AssessmentRepository repo;
  LaunchAssessmentUseCase(this.repo);
  Future<Assessment> call(String activityId) async {
    // Si ya existe, retornar el existente.
    final existing = await repo.getByActivity(activityId);
    if (existing != null) return existing;
    final assessment = Assessment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityId: activityId,
      launchedAt: DateTime.now(),
    );
    return repo.create(assessment);
  }
}

class GetAssessmentByActivityUseCase {
  final AssessmentRepository repo;
  GetAssessmentByActivityUseCase(this.repo);
  Future<Assessment?> call(String activityId) => repo.getByActivity(activityId);
}

class CloseAssessmentUseCase {
  final AssessmentRepository repo;
  CloseAssessmentUseCase(this.repo);
  Future<bool> call(String activityId) => repo.close(activityId);
}
