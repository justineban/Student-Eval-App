import '../models/course_model.dart';

abstract class CourseRepository {
  Future<CourseModel> createCourse({required String name, required String description, required String teacherId});
  Future<List<CourseModel>> getCoursesByTeacher(String teacherId);
  Future<CourseModel?> getCourseById(String id);
  Future<CourseModel> inviteStudent({required String courseId, required String teacherId, required String email});
  Future<CourseModel> updateCourse({required String id, required String name, required String description, required String teacherId});
  Future<void> deleteCourse({required String id, required String teacherId});
  // Student-side operations
  Future<CourseModel?> getCourseByRegistrationCode(String code);
  Future<CourseModel?> joinCourseByCode({required String code, required String studentId});
  Future<List<CourseModel>> getCoursesByStudent(String studentId);
  Future<List<CourseModel>> getInvitedCoursesForEmail(String email);
  Future<CourseModel?> acceptInvitation({required String courseId, required String email, required String studentId});
}
