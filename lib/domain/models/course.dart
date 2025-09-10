class Course {
  final String id;
  final String name;
  final String description;
  final List<String> enrolledUserIds;
  final String ownerId;
  final String ownerName;
  final String registrationCode;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.registrationCode,
    List<String>? enrolledUserIds,
  }) : enrolledUserIds = enrolledUserIds ?? [];
}
