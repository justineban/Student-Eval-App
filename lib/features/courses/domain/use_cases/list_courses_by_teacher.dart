import '../entities/course.dart';
import '../repositories/course_repository.dart';

class ListCoursesByTeacherUseCase {
  final CourseRepository courseRepository;
  ListCoursesByTeacherUseCase(this.courseRepository);

  Future<List<CourseEntity>> call(String teacherId) => courseRepository.listByTeacher(teacherId);
}
