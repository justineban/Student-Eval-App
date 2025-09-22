class GroupEntity {
  final String id;
  final String categoryId;
  final String name;
  final List<String> memberIds;
  const GroupEntity({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.memberIds,
  });

  GroupEntity copyWith({
    String? name,
    List<String>? memberIds,
  }) => GroupEntity(
    id: id,
    categoryId: categoryId,
    name: name ?? this.name,
    memberIds: memberIds ?? this.memberIds,
  );
}
