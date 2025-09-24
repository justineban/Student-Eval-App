import '../models/peer_evaluation_model.dart';
import '../repositories/peer_evaluation_repository.dart';

class GetReceivedPeerEvaluationsUseCase {
  final PeerEvaluationRepository repo;
  GetReceivedPeerEvaluationsUseCase(this.repo);

  Future<List<PeerEvaluationModel>> call({required String assessmentId, required String evaluateeId}) {
    return repo.getByAssessmentAndEvaluatee(assessmentId: assessmentId, evaluateeId: evaluateeId);
  }
}
