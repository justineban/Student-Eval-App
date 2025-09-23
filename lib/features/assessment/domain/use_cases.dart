import 'assessment_repository.dart';
import 'assessment_entity.dart';

class CreateAssessmentUseCase {
  final AssessmentRepository repo;
  CreateAssessmentUseCase(this.repo);
  Future<Assessment> call(Assessment a) => repo.create(a);
}

class GetAssessmentByIdUseCase {
  final AssessmentRepository repo;
  GetAssessmentByIdUseCase(this.repo);
  Future<Assessment?> call(String id) => repo.getById(id);
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
