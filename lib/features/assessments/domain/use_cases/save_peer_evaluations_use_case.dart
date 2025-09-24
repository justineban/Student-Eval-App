import '../models/peer_evaluation_model.dart';
import '../repositories/peer_evaluation_repository.dart';

class SavePeerEvaluationsUseCase {
  final PeerEvaluationRepository repo;
  SavePeerEvaluationsUseCase(this.repo);
  Future<void> call(List<PeerEvaluationModel> list) => repo.saveAll(list);
}
