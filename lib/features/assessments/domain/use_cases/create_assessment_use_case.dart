import '../models/assessment_model.dart';
import '../repositories/assessment_repository.dart';

class CreateAssessmentUseCase {
  final AssessmentRepository repository;
  CreateAssessmentUseCase(this.repository);

  Future<AssessmentModel> call({
    required String courseId,
    required String activityId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    required bool gradesVisible,
  }) => repository.create(
        courseId: courseId,
        activityId: activityId,
        title: title,
        durationMinutes: durationMinutes,
        startAt: startAt,
        gradesVisible: gradesVisible,
      );
}
