/// Activity entity representing an assignment / task inside a course category or directly a course.
/// Mantener simple como las demás entidades del core.
class Activity {
  final String id;
  final String courseId; // vinculación al curso
  String
  categoryId; // ahora obligatorio y mutable: cada actividad pertenece a una categoría
  String title;
  String description;
  DateTime? dueDate;
  int maxScore;
  // Lista de IDs de estudiantes que ya enviaron algo (para simplificar)
  List<String> submissions;

  Activity({
    required this.id,
    required this.courseId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.dueDate,
    required this.maxScore,
    List<String>? submissions,
  }) : submissions = submissions ?? [];
}
