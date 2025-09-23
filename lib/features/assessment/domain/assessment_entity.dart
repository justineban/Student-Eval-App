class Assessment {
  final String id;
  final String activityId;
  String name;
  int durationMinutes; // duración en minutos
  DateTime createdAt;
  bool closed;
  bool publicResults; // si los estudiantes pueden ver resultados
  DateTime? closedAt;

  Assessment({
    required this.id,
    required this.activityId,
    required this.name,
    required this.durationMinutes,
    required this.createdAt,
    this.closed = false,
    this.publicResults = false,
    this.closedAt,
  });

  DateTime get startAt => createdAt;
  DateTime get endAt => startAt.add(Duration(minutes: durationMinutes));
  bool get isExpired => DateTime.now().isAfter(endAt) || closed;
  bool get isActive => !closed && !isExpired;
  bool get isClosed => closed;
  int get remainingMinutes {
    if (isClosed) return 0;
    final diff = endAt.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inMinutes;
  }
}
