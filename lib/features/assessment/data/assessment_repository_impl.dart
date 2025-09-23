import '../domain/assessment_entity.dart';
import '../domain/assessment_repository.dart';
import 'assessment_memory_datasource.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentMemoryDataSource _ds = AssessmentMemoryDataSource();

  @override
  Future<Assessment> create(Assessment assessment) => _ds.create(assessment);

  @override
  Future<Assessment?> getByActivity(String activityId) =>
      _ds.getByActivity(activityId);

  @override
  Future<Assessment?> getById(String id) => _ds.getById(id);

  @override
  Future<bool> close(String activityId) => _ds.close(activityId);
}
