import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/assessment_model.dart';

abstract class AssessmentLocalDataSource {
  Future<AssessmentModel> save(AssessmentModel a);
  Future<AssessmentModel?> fetchByActivity(String activityId);
  Future<AssessmentModel> update(AssessmentModel a);
  Future<void> deleteByActivity(String activityId);
}

class HiveAssessmentLocalDataSource implements AssessmentLocalDataSource {
  late final Box _box;
  HiveAssessmentLocalDataSource({Box? box}) { _box = box ?? Hive.box(HiveBoxes.activities); }
  // NOTE: Ideally use its own box, but to minimize setup we reuse activities box with distinct keys

  String _key(String id) => 'assessment_$id';
  String _keyByActivity(String activityId) => 'assessment_by_activity_$activityId';

  @override
  Future<AssessmentModel> save(AssessmentModel a) async {
    await _box.put(_key(a.id), {
      'id': a.id,
      'courseId': a.courseId,
      'activityId': a.activityId,
      'title': a.title,
      'durationMinutes': a.durationMinutes,
      'startAt': a.startAt.toIso8601String(),
      'gradesVisible': a.gradesVisible,
      'cancelled': a.cancelled,
    });
    await _box.put(_keyByActivity(a.activityId), a.id);
    return a;
  }

  @override
  Future<AssessmentModel?> fetchByActivity(String activityId) async {
    final id = _box.get(_keyByActivity(activityId));
    if (id is String) {
      final data = _box.get(_key(id));
      if (data is Map) return _fromMap(data);
    }
    return null;
  }

  @override
  Future<AssessmentModel> update(AssessmentModel a) async {
    return save(a);
  }

  @override
  Future<void> deleteByActivity(String activityId) async {
    final id = _box.get(_keyByActivity(activityId));
    if (id is String) {
      await _box.delete(_key(id));
    }
    await _box.delete(_keyByActivity(activityId));
  }

  AssessmentModel _fromMap(Map map) => AssessmentModel(
        id: map['id'] as String,
        courseId: map['courseId'] as String,
        activityId: map['activityId'] as String,
        title: map['title'] as String,
        durationMinutes: map['durationMinutes'] as int,
        startAt: DateTime.parse(map['startAt'] as String),
        gradesVisible: map['gradesVisible'] as bool,
        cancelled: (map['cancelled'] as bool?) ?? false,
      );
}
