import 'package:uuid/uuid.dart';
import '../../domain/models/assessment_model.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../datasources/assessment_local_datasource.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentLocalDataSource local;
  final _uuid = const Uuid();
  AssessmentRepositoryImpl({required this.local});

  @override
  Future<AssessmentModel> create({
    required String courseId,
    required String activityId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    required bool gradesVisible,
  }) async {
    final existing = await local.fetchByActivity(activityId);
    if (existing != null) return existing; // enforce single assessment per activity
    final a = AssessmentModel(
      id: _uuid.v4(),
      courseId: courseId,
      activityId: activityId,
      title: title,
      durationMinutes: durationMinutes,
      startAt: startAt,
      gradesVisible: gradesVisible,
    );
    return await local.save(a);
  }

  @override
  Future<AssessmentModel?> getByActivity(String activityId) => local.fetchByActivity(activityId);

  @override
  Future<AssessmentModel> update(AssessmentModel a) => local.update(a);

  @override
  Future<void> deleteByActivity(String activityId) => local.deleteByActivity(activityId);
}
