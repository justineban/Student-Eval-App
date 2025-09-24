import '../models/peer_evaluation_model.dart';

abstract class PeerEvaluationRepository {
  Future<void> saveAll(List<PeerEvaluationModel> list);
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluator({required String assessmentId, required String evaluatorId});
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluatee({required String assessmentId, required String evaluateeId});
}
