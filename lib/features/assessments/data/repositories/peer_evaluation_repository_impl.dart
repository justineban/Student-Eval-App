import '../../domain/models/peer_evaluation_model.dart';
import '../../domain/repositories/peer_evaluation_repository.dart';
import '../datasources/peer_evaluation_local_datasource.dart';
import '../datasources/peer_evaluation_remote_roble_datasource.dart';

class PeerEvaluationRepositoryImpl implements PeerEvaluationRepository {
  final PeerEvaluationRemoteDataSource remote;
  final PeerEvaluationLocalDataSource? localCache;
  PeerEvaluationRepositoryImpl({required this.remote, this.localCache});

  @override
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluator({required String assessmentId, required String evaluatorId}) async {
    final list = await remote.getByAssessmentAndEvaluator(assessmentId, evaluatorId);
    if (localCache != null) {
      await localCache!.saveAll(list);
    }
    return list;
  }

  @override
  Future<void> saveAll(List<PeerEvaluationModel> list) async {
    await remote.saveAll(list);
    if (localCache != null) {
      await localCache!.saveAll(list);
    }
  }

  @override
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluatee({required String assessmentId, required String evaluateeId}) async {
    final list = await remote.getByAssessmentAndEvaluatee(assessmentId, evaluateeId);
    // no specific cache index for evaluatee, but we can still mirror with saveAll
    if (localCache != null) {
      await localCache!.saveAll(list);
    }
    return list;
  }
}
