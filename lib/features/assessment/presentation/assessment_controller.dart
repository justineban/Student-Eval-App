import 'package:flutter/material.dart';
import '../domain/assessment_entity.dart';
import '../domain/assessment_repository.dart';
import '../data/assessment_repository_impl.dart';
import '../domain/peer_evaluation_entity.dart';
import '../domain/peer_evaluation_repository.dart';
import '../data/peer_evaluation_repository_impl.dart';
import '../domain/criterion.dart';

class AggregatedResult {
  final String targetUserId;
  final Map<String, double> averages; // criterio -> promedio
  final double globalAverage;
  final int receivedCount;
  AggregatedResult({
    required this.targetUserId,
    required this.averages,
    required this.globalAverage,
    required this.receivedCount,
  });
}

class AssessmentController with ChangeNotifier {
  final AssessmentRepository _assRepo = AssessmentRepositoryImpl();
  final PeerEvaluationRepository _peerRepo = PeerEvaluationRepositoryImpl();

  final Map<String, Assessment?> _byActivity = {}; // activityId -> assessment
  final Map<String, List<PeerEvaluation>> _evaluationsCache =
      {}; // assessmentId -> evals
  final Map<String, List<AggregatedResult>> _aggregatedCache =
      {}; // assessmentId -> aggregated

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }

  void _setError(Object e) {
    _loading = false;
    _error = e.toString();
    notifyListeners();
  }

  Assessment? assessmentForActivity(String activityId) =>
      _byActivity[activityId];

  Future<Assessment?> loadAssessment(String activityId) async {
    _setLoading(true);
    try {
      final a = await _assRepo.getByActivity(activityId);
      _byActivity[activityId] = a;
      _setLoading(false);
      return a;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<Assessment?> launchAssessment({
    required String activityId,
    required String name,
    required int durationMinutes,
    required bool publicResults,
  }) async {
    _setLoading(true);
    try {
      // si ya existe, retornarlo
      final existing = await _assRepo.getByActivity(activityId);
      if (existing != null) {
        _byActivity[activityId] = existing;
        _setLoading(false);
        return existing;
      }
      final a = Assessment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        activityId: activityId,
        name: name,
        durationMinutes: durationMinutes,
        createdAt: DateTime.now(),
        publicResults: publicResults,
      );
      final created = await _assRepo.create(a);
      _byActivity[activityId] = created;
      _setLoading(false);
      return created;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<bool> closeAssessment(String activityId) async {
    _setLoading(true);
    try {
      final ok = await _assRepo.close(activityId);
      if (ok) {
        final a = _byActivity[activityId];
        if (a != null) {
          a.closed = true;
          a.closedAt = DateTime.now();
        }
      }
      _setLoading(false);
      return ok;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  bool canStudentEvaluate(
    String activityId,
    String userId,
    List<String> groupMemberIds,
  ) {
    final a = _byActivity[activityId];
    if (a == null) return false;
    if (a.isExpired) return false;
    if (groupMemberIds.length <= 1) return false; // no peers
    return true;
  }

  Future<PeerEvaluation?> submitEvaluation({
    required String assessmentId,
    required String evaluatorUserId,
    required String targetUserId,
    required Map<String, int> criteriaScores,
    String? comment,
  }) async {
    _setLoading(true);
    try {
      // Validación niveles
      for (final entry in criteriaScores.entries) {
        if (!allowedCriterionLevels.contains(entry.value)) {
          throw Exception('Nivel inválido para criterio ${entry.key}');
        }
      }
      final eval = PeerEvaluation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        assessmentId: assessmentId,
        evaluatorUserId: evaluatorUserId,
        targetUserId: targetUserId,
        criteriaScores: Map<String, int>.from(criteriaScores),
        comment: comment,
        submittedAt: DateTime.now(),
      );
      final stored = await _peerRepo.submit(eval);
      // invalidate caches
      _evaluationsCache.remove(assessmentId);
      _aggregatedCache.remove(assessmentId);
      _setLoading(false);
      return stored;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<List<PeerEvaluation>> loadEvaluations(String assessmentId) async {
    if (_evaluationsCache.containsKey(assessmentId)) {
      return _evaluationsCache[assessmentId]!;
    }
    try {
      final list = await _peerRepo.listByAssessment(assessmentId);
      _evaluationsCache[assessmentId] = list;
      return list;
    } catch (e) {
      _setError(e);
      return [];
    }
  }

  Future<List<AggregatedResult>> aggregate(String assessmentId) async {
    if (_aggregatedCache.containsKey(assessmentId)) {
      return _aggregatedCache[assessmentId]!;
    }
    final evals = await loadEvaluations(assessmentId);
    final Map<String, List<PeerEvaluation>> byTarget = {};
    for (final e in evals) {
      byTarget.putIfAbsent(e.targetUserId, () => []).add(e);
    }
    final List<AggregatedResult> results = [];
    for (final entry in byTarget.entries) {
      final targetId = entry.key;
      final list = entry.value;
      final Map<String, double> avg = {};
      for (final c in criteriaList) {
        final values = list
            .map((e) => e.criteriaScores[c.key] ?? 0)
            .where((v) => v > 0)
            .toList();
        final mean = values.isEmpty
            ? 0.0
            : values.reduce((a, b) => a + b) / values.length;
        avg[c.key] = mean;
      }
      final allScores = list
          .expand((e) => e.criteriaScores.values)
          .where((v) => v > 0)
          .toList();
      final global = allScores.isEmpty
          ? 0.0
          : allScores.reduce((a, b) => a + b) / allScores.length;
      results.add(
        AggregatedResult(
          targetUserId: targetId,
          averages: avg,
          globalAverage: global,
          receivedCount: list.length,
        ),
      );
    }
    _aggregatedCache[assessmentId] = results;
    return results;
  }
}
