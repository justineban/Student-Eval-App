import '../entities/course.dart';

abstract class CourseRepository {
  Future<CourseEntity> create(CourseEntity course);
  Future<CourseEntity?> getById(String id);
  Future<CourseEntity?> getByRegistrationCode(String code);
  Future<void> save(CourseEntity course);
  Future<void> addInvitation(String courseId, String email);
  Future<void> addStudent(String courseId, String userId);
  Future<void> removeInvitation(String courseId, String email);
  Future<List<CourseEntity>> listAll();
  Future<List<CourseEntity>> listByTeacher(String teacherId);
  Future<List<CourseEntity>> listByStudent(String studentId);
  Future<List<CourseEntity>> listByInvitationEmail(String email);
}
