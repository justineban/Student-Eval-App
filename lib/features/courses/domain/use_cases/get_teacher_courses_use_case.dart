import '../repositories/course_repository.dart';
import '../models/course_model.dart';

class GetTeacherCoursesUseCase {
  final CourseRepository repository;
  GetTeacherCoursesUseCase(this.repository);

  Future<List<CourseModel>> call(String teacherId) {
    return repository.getCoursesByTeacher(teacherId);
  }
}
