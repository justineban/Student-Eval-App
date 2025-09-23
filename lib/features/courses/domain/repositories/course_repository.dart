import '../models/course_model.dart';

abstract class CourseRepository {
  Future<CourseModel> createCourse({required String name, required String description, required String teacherId});
  Future<List<CourseModel>> getCoursesByTeacher(String teacherId);
  Future<CourseModel?> getCourseById(String id);
  Future<CourseModel> inviteStudent({required String courseId, required String teacherId, required String email});
}
