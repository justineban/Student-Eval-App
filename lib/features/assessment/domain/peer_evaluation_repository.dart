import 'peer_evaluation_entity.dart';

abstract class PeerEvaluationRepository {
  Future<PeerEvaluation> submit(PeerEvaluation eval);
  Future<List<PeerEvaluation>> listByAssessment(String assessmentId);
  Future<List<PeerEvaluation>> listByEvaluator(
    String assessmentId,
    String evaluatorId,
  );
  Future<bool> hasEvaluation(
    String assessmentId,
    String evaluatorId,
    String targetUserId,
  );
}
