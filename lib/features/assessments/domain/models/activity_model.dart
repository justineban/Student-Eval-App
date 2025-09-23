class ActivityModel {
  final String id;
  final String courseId;
  final String categoryId;
  String name;
  String description;
  DateTime? dueDate;
  bool visible;

  ActivityModel({
    required this.id,
    required this.courseId,
    required this.categoryId,
    required this.name,
    required this.description,
    this.dueDate,
    required this.visible,
  });
}
