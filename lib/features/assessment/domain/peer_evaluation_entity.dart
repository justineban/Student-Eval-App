class PeerEvaluation {
  final String id;
  final String assessmentId;
  final String evaluatorUserId;
  final String targetUserId;
  final Map<String, int> criteriaScores; // key -> level (2,3,4,5)
  final String? comment; // visible solo a docente
  final DateTime submittedAt;

  PeerEvaluation({
    required this.id,
    required this.assessmentId,
    required this.evaluatorUserId,
    required this.targetUserId,
    required this.criteriaScores,
    this.comment,
    required this.submittedAt,
  });
}
