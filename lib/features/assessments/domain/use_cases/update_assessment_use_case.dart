import '../models/assessment_model.dart';
import '../repositories/assessment_repository.dart';

class UpdateAssessmentUseCase {
  final AssessmentRepository repository;
  UpdateAssessmentUseCase(this.repository);

  Future<AssessmentModel> call(AssessmentModel a) => repository.update(a);
}
