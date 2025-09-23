/// Assessment lanzado para una Activity.
/// Solo puede existir uno activo por Activity según requerimiento.
class Assessment {
  final String id;
  final String activityId;
  final DateTime launchedAt;
  bool closed; // permitir cerrar evaluación

  Assessment({
    required this.id,
    required this.activityId,
    required this.launchedAt,
    this.closed = false,
  });
}
