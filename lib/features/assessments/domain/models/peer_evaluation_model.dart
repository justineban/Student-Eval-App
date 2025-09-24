class PeerEvaluationModel {
  final String id; // unique per (assessmentId + evaluatorId + evaluateeId)
  final String assessmentId;
  final String evaluatorId;
  final String evaluateeId;
  final int punctuality;   // 2..5
  final int contributions; // 2..5
  final int commitment;    // 2..5
  final int attitude;      // 2..5

  const PeerEvaluationModel({
    required this.id,
    required this.assessmentId,
    required this.evaluatorId,
    required this.evaluateeId,
    required this.punctuality,
    required this.contributions,
    required this.commitment,
    required this.attitude,
  });

  PeerEvaluationModel copyWith({
    int? punctuality,
    int? contributions,
    int? commitment,
    int? attitude,
  }) => PeerEvaluationModel(
        id: id,
        assessmentId: assessmentId,
        evaluatorId: evaluatorId,
        evaluateeId: evaluateeId,
        punctuality: punctuality ?? this.punctuality,
        contributions: contributions ?? this.contributions,
        commitment: commitment ?? this.commitment,
        attitude: attitude ?? this.attitude,
      );
}
