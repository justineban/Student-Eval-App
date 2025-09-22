class CourseEntity {
  final String id;
  final String name;
  final String description;
  final String teacherId;
  final String registrationCode;
  final List<String> studentIds;
  final List<String> invitations;
  const CourseEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.teacherId,
    required this.registrationCode,
    required this.studentIds,
    required this.invitations,
  });

  CourseEntity copyWith({
    String? name,
    String? description,
    List<String>? studentIds,
    List<String>? invitations,
  }) => CourseEntity(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    teacherId: teacherId,
    registrationCode: registrationCode,
    studentIds: studentIds ?? this.studentIds,
    invitations: invitations ?? this.invitations,
  );
}
