import 'package:uuid/uuid.dart';
import '../../domain/models/assessment_model.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../datasources/assessment_local_datasource.dart';
import '../datasources/assessment_remote_roble_datasource.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentRemoteDataSource remote;
  final AssessmentLocalDataSource? localCache;
  final _uuid = const Uuid();
  AssessmentRepositoryImpl({required this.remote, this.localCache});

  @override
  Future<AssessmentModel> create({
    required String courseId,
    required String activityId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    required bool gradesVisible,
  }) async {
    final id = _uuid.v4();
    final created = await remote.create(
      id: id,
      courseId: courseId,
      activityId: activityId,
      title: title,
      durationMinutes: durationMinutes,
      startAt: startAt,
      gradesVisible: gradesVisible,
    );
    if (localCache != null) {
      await localCache!.save(created);
    }
    return created;
  }

  @override
  Future<AssessmentModel?> getByActivity(String activityId) async {
    final a = await remote.getByActivity(activityId);
    if (a != null && localCache != null) {
      await localCache!.save(a);
    }
    return a;
  }

  @override
  Future<AssessmentModel> update(AssessmentModel a) async {
    final updated = await remote.update(a);
    if (localCache != null) {
      await localCache!.update(updated);
    }
    return updated;
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    await remote.deleteByActivity(activityId);
    if (localCache != null) {
      await localCache!.deleteByActivity(activityId);
    }
  }
}
