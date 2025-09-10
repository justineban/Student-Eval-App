class Category {
  final String id;
  final String courseId;
  String name;
  String groupingMethod;
  int maxStudentsPerGroup;
  // studentGroups will hold group ids; groups are stored separately in the service
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

class Group {
  final String id;
  final String categoryId;
  final String name;
  final List<String> memberUserIds;

  Group({
    required this.id,
    required this.categoryId,
    required this.name,
    List<String>? memberUserIds,
  }) : memberUserIds = memberUserIds ?? [];
}

