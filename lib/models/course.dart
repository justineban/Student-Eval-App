class Course {
  final String id;
  final String name;
  final String description;
  final List<String> enrolledUserIds;

  Course({
    required this.id,
    required this.name,
    required this.description,
    List<String>? enrolledUserIds,
  }) : enrolledUserIds = enrolledUserIds ?? [];
}
