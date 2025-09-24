import '../models/assessment_model.dart';

abstract class AssessmentRepository {
  Future<AssessmentModel> create({
    required String courseId,
    required String activityId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    required bool gradesVisible,
  });
  Future<AssessmentModel?> getByActivity(String activityId);
  Future<AssessmentModel> update(AssessmentModel a);
  Future<void> deleteByActivity(String activityId);
}
