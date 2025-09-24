import '../models/assessment_model.dart';
import '../repositories/assessment_repository.dart';

class GetAssessmentByActivityUseCase {
  final AssessmentRepository repository;
  GetAssessmentByActivityUseCase(this.repository);

  Future<AssessmentModel?> call(String activityId) => repository.getByActivity(activityId);
}
