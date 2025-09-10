import '../../domain/models/course.dart';

abstract class CourseRepository {
  List<Course> get courses;
  List<Course> getAllCourses();
  Future<Course> addCourse(String name, String description);
  Future<bool> enrollByCode(String registrationCode, String userId);
  Course? getCourse(String id);
  Future<bool> enrollUser(String courseId, String userId);
  List<Course> getEnrolledCourses(String userId);
  int countCoursesForUser(String userId);
}
