//   placeholder of peer_evaluation_entity (not fully read) - adjust as needed.
class PeerEvaluationModel  {
  final String id;
  final String assessmentId;
  final String evaluatorId;
  final String evaluateeId;
  double score;

  PeerEvaluationModel ({
    required this.id,
    required this.assessmentId,
    required this.evaluatorId,
    required this.evaluateeId,
    required this.score,
  });
}
