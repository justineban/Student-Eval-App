class Category {
  final String id;
  final String courseId;
  String name;
  String groupingMethod;
  int maxStudentsPerGroup;
  List<String> studentGroups;

  Category({
    required this.id,
    required this.courseId,
    required this.name,
    required this.groupingMethod,
    required this.maxStudentsPerGroup,
    List<String>? studentGroups,
  }) : studentGroups = studentGroups ?? [];
}
