class CategoryEntity {
  final String id;
  final String courseId;
  final String name;
  final bool randomAssign;
  final int studentsPerGroup;
  const CategoryEntity({
    required this.id,
    required this.courseId,
    required this.name,
    required this.randomAssign,
    required this.studentsPerGroup,
  });

  CategoryEntity copyWith({
    String? name,
    bool? randomAssign,
    int? studentsPerGroup,
  }) => CategoryEntity(
    id: id,
    courseId: courseId,
    name: name ?? this.name,
    randomAssign: randomAssign ?? this.randomAssign,
    studentsPerGroup: studentsPerGroup ?? this.studentsPerGroup,
  );
}
