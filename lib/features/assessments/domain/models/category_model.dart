class CategoryModel {
  final String id;
  final String courseId;
  String name;
  bool randomGroups;
  int maxStudentsPerGroup;

  CategoryModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.randomGroups,
    required this.maxStudentsPerGroup,
  });
}
