import '../../domain/models/peer_evaluation_model.dart';
import '../../domain/repositories/peer_evaluation_repository.dart';
import '../datasources/peer_evaluation_local_datasource.dart';

class PeerEvaluationRepositoryImpl implements PeerEvaluationRepository {
  final PeerEvaluationLocalDataSource local;
  PeerEvaluationRepositoryImpl({required this.local});

  @override
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluator({required String assessmentId, required String evaluatorId}) {
    return local.fetchByAssessmentAndEvaluator(assessmentId, evaluatorId);
  }

  @override
  Future<void> saveAll(List<PeerEvaluationModel> list) => local.saveAll(list);

  @override
  Future<List<PeerEvaluationModel>> getByAssessmentAndEvaluatee({required String assessmentId, required String evaluateeId}) {
    return local.fetchByAssessmentAndEvaluatee(assessmentId, evaluateeId);
  }
}
