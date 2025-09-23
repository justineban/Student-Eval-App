import '../domain/assessment_entity.dart';

class AssessmentMemoryDataSource {
  static final AssessmentMemoryDataSource _instance =
      AssessmentMemoryDataSource._internal();
  factory AssessmentMemoryDataSource() => _instance;
  AssessmentMemoryDataSource._internal();

  final Map<String, Assessment> _assessmentsByActivity =
      {}; // activityId -> Assessment

  Assessment? getByActivity(String activityId) =>
      _assessmentsByActivity[activityId];

  Assessment create(Assessment assessment) {
    _assessmentsByActivity[assessment.activityId] = assessment;
    return assessment;
  }

  bool close(String activityId) {
    final a = _assessmentsByActivity[activityId];
    if (a == null) return false;
    a.closed = true;
    return true;
  }
}
