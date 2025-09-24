import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class GetStudentCoursesUseCase {
  final CourseRepository repository;
  GetStudentCoursesUseCase(this.repository);

  Future<List<CourseModel>> call(String studentId) {
    return repository.getCoursesByStudent(studentId);
  }
}
