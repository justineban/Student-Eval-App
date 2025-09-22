import '../entities/course.dart';
import '../repositories/course_repository.dart';

class ListCoursesByStudentUseCase {
  final CourseRepository courseRepository;
  ListCoursesByStudentUseCase(this.courseRepository);

  Future<List<CourseEntity>> call(String studentId) => courseRepository.listByStudent(studentId);
}
