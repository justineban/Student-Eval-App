import '../repositories/assessment_repository.dart';

class DeleteAssessmentByActivityUseCase {
  final AssessmentRepository repo;
  DeleteAssessmentByActivityUseCase(this.repo);

  Future<void> call(String activityId) => repo.deleteByActivity(activityId);
}
