import '../domain/assessment_entity.dart';
import '../domain/assessment_repository.dart';
import 'assessment_memory_datasource.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentMemoryDataSource _ds = AssessmentMemoryDataSource();

  @override
  Future<Assessment> create(Assessment assessment) async =>
      _ds.create(assessment);

  @override
  Future<Assessment?> getByActivity(String activityId) async =>
      _ds.getByActivity(activityId);

  @override
  Future<bool> close(String activityId) async => _ds.close(activityId);
}
