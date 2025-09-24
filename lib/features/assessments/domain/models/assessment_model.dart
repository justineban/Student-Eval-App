// Simple model for an evaluation (assessment) linked to an activity
class AssessmentModel {
  final String id;
  final String courseId;
  final String activityId;
  String title;
  int durationMinutes; // time limit
  DateTime startAt; // start time
  bool gradesVisible; // visibility of grades for students
  bool cancelled;

  AssessmentModel({
    required this.id,
    required this.courseId,
    required this.activityId,
    required this.title,
    required this.durationMinutes,
    required this.startAt,
    required this.gradesVisible,
    this.cancelled = false,
  });

  DateTime get endAt => startAt.add(Duration(minutes: durationMinutes));
}
