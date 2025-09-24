import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/peer_evaluation_model.dart';

abstract class PeerEvaluationLocalDataSource {
  Future<void> saveAll(List<PeerEvaluationModel> list);
  Future<List<PeerEvaluationModel>> fetchByAssessmentAndEvaluator(String assessmentId, String evaluatorId);
  Future<List<PeerEvaluationModel>> fetchByAssessmentAndEvaluatee(String assessmentId, String evaluateeId);
}

class HivePeerEvaluationLocalDataSource implements PeerEvaluationLocalDataSource {
  late final Box _box;
  HivePeerEvaluationLocalDataSource({Box? box}) { _box = box ?? Hive.box(HiveBoxes.assessments); }

  String _key(String id) => 'peer_eval_$id';
  String _indexKey(String assessmentId, String evaluatorId) => 'peer_eval_index_${assessmentId}_$evaluatorId';

  @override
  Future<void> saveAll(List<PeerEvaluationModel> list) async {
    if (list.isEmpty) return;
    for (final e in list) {
      await _box.put(_key(e.id), {
        'id': e.id,
        'assessmentId': e.assessmentId,
        'evaluatorId': e.evaluatorId,
        'evaluateeId': e.evaluateeId,
        'punctuality': e.punctuality,
        'contributions': e.contributions,
        'commitment': e.commitment,
        'attitude': e.attitude,
      });
    }
    // maintain index
    final aId = list.first.assessmentId;
    final evId = list.first.evaluatorId;
    final ids = list.map((e) => e.id).toList();
    await _box.put(_indexKey(aId, evId), ids);
  }

  @override
  Future<List<PeerEvaluationModel>> fetchByAssessmentAndEvaluator(String assessmentId, String evaluatorId) async {
    final result = <PeerEvaluationModel>[];
    final ids = (_box.get(_indexKey(assessmentId, evaluatorId)) as List?)?.cast<String>() ?? const <String>[];
    for (final id in ids) {
      final data = _box.get(_key(id));
      if (data is Map) {
        result.add(PeerEvaluationModel(
          id: data['id'] as String,
          assessmentId: data['assessmentId'] as String,
          evaluatorId: data['evaluatorId'] as String,
          evaluateeId: data['evaluateeId'] as String,
          punctuality: data['punctuality'] as int,
          contributions: data['contributions'] as int,
          commitment: data['commitment'] as int,
          attitude: data['attitude'] as int,
        ));
      }
    }
    return result;
  }

  @override
  Future<List<PeerEvaluationModel>> fetchByAssessmentAndEvaluatee(String assessmentId, String evaluateeId) async {
    final result = <PeerEvaluationModel>[];
    // Scan keys with our peer eval prefix and filter. Acceptable for local scale.
    for (final key in _box.keys) {
      if (key is String && key.startsWith('peer_eval_')) {
        final data = _box.get(key);
        if (data is Map) {
          if (data['assessmentId'] == assessmentId && data['evaluateeId'] == evaluateeId) {
            result.add(PeerEvaluationModel(
              id: data['id'] as String,
              assessmentId: data['assessmentId'] as String,
              evaluatorId: data['evaluatorId'] as String,
              evaluateeId: data['evaluateeId'] as String,
              punctuality: data['punctuality'] as int,
              contributions: data['contributions'] as int,
              commitment: data['commitment'] as int,
              attitude: data['attitude'] as int,
            ));
          }
        }
      }
    }
    return result;
  }
}
