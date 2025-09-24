class GroupModel {
  final String id;
  final String courseId;
  final String categoryId;
  String name;
  List<String> memberIds;

  GroupModel({
    required this.id,
    required this.courseId,
    required this.categoryId,
    required this.name,
    List<String>? memberIds,
  })  : memberIds = memberIds ?? [];
}
