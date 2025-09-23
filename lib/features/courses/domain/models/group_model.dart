//   of core/entities/group.dart for courses module (detached)
class GroupModel  {
  final String id;
  final String categoryId;
  String name;
  List<String> memberIds;

  GroupModel ({required this.id, required this.categoryId, required this.name, List<String>? memberIds})
      : memberIds = memberIds ?? [];
}
