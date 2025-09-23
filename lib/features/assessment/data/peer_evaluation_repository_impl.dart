import '../domain/peer_evaluation_entity.dart';
import '../domain/peer_evaluation_repository.dart';

class PeerEvaluationRepositoryImpl implements PeerEvaluationRepository {
  final Map<String, PeerEvaluation> _byId = {}; // id -> eval
  final Map<String, List<String>> _byAssessment =
      {}; // assessmentId -> eval ids
  final Map<String, Set<String>> _uniqueKey =
      {}; // assessmentId -> set(evaluatorId|targetId)

  @override
  Future<bool> hasEvaluation(
    String assessmentId,
    String evaluatorUserId,
    String targetUserId,
  ) async {
    final set = _uniqueKey[assessmentId];
    if (set == null) return false;
    return set.contains(_pairKey(evaluatorUserId, targetUserId));
  }

  String _pairKey(String evaluator, String target) => '$evaluator|$target';

  @override
  Future<List<PeerEvaluation>> listByAssessment(String assessmentId) async {
    final ids = _byAssessment[assessmentId];
    if (ids == null) return [];
    return ids.map((e) => _byId[e]!).toList();
  }

  @override
  Future<List<PeerEvaluation>> listByEvaluator(
    String assessmentId,
    String evaluatorId,
  ) async {
    final all = await listByAssessment(assessmentId);
    return all.where((e) => e.evaluatorUserId == evaluatorId).toList();
  }

  @override
  Future<PeerEvaluation> submit(PeerEvaluation eval) async {
    final key = _pairKey(eval.evaluatorUserId, eval.targetUserId);
    final existing = await hasEvaluation(
      eval.assessmentId,
      eval.evaluatorUserId,
      eval.targetUserId,
    );
    if (existing) {
      // Ignoramos duplicado; retornamos el ya registrado (simplificación: no almacenamos ref previa)
      // En alternativa podríamos lanzar excepción.
      final previous = (await listByAssessment(eval.assessmentId)).firstWhere(
        (e) =>
            e.evaluatorUserId == eval.evaluatorUserId &&
            e.targetUserId == eval.targetUserId,
      );
      return previous;
    }
    _byId[eval.id] = eval;
    _byAssessment.putIfAbsent(eval.assessmentId, () => []).add(eval.id);
    _uniqueKey.putIfAbsent(eval.assessmentId, () => <String>{}).add(key);
    return eval;
  }
}
