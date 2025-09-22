class Group {
  final String id;
  final String categoryId;
  String name;
  List<String> memberIds;

  Group({required this.id, required this.categoryId, required this.name, List<String>? memberIds}) : memberIds = memberIds ?? [];
}
