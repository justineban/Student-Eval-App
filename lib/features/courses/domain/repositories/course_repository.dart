import '../models/course_model.dart';

abstract class CourseRepository {
  Future<CourseModel> createCourse({required String name, required String description, required String teacherId});
  Future<List<CourseModel>> getCoursesByTeacher(String teacherId);
}
