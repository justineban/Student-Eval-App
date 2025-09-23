import '../domain/assessment_entity.dart';

class AssessmentMemoryDataSource {
  final Map<String, Assessment> _byId = {}; // id -> assessment
  final Map<String, String> _byActivity = {}; // activityId -> assessmentId

  Future<Assessment> create(Assessment a) async {
    // solo permitir uno por actividad (si ya existe retornarlo)
    final existingId = _byActivity[a.activityId];
    if (existingId != null) {
      return _byId[existingId]!;
    }
    _byId[a.id] = a;
    _byActivity[a.activityId] = a.id;
    return a;
  }

  Future<Assessment?> getById(String id) async => _byId[id];
  Future<Assessment?> getByActivity(String activityId) async {
    final id = _byActivity[activityId];
    if (id == null) return null;
    return _byId[id];
  }

  Future<bool> close(String activityId) async {
    final id = _byActivity[activityId];
    if (id == null) return false;
    final a = _byId[id];
    if (a == null) return false;
    a.closed = true;
    a.closedAt = DateTime.now();
    return true;
  }
}
