import 'assessment_entity.dart';

abstract class AssessmentRepository {
  Future<Assessment> create(Assessment assessment);
  Future<Assessment?> getById(String id);
  Future<Assessment?> getByActivity(String activityId);
  Future<bool> close(String activityId);
}
