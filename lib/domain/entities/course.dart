class Course {
  final String id;
  String name;
  String description;
  String teacherId;
  String registrationCode;
  List<String> studentIds;
  List<String> invitations; // emails invited

  Course({required this.id, required this.name, required this.description, required this.teacherId, required this.registrationCode, List<String>? studentIds, List<String>? invitations}) : studentIds = studentIds ?? [], invitations = invitations ?? [];
}
