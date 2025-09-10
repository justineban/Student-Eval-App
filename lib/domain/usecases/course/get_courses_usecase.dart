import '../../models/course.dart';
import '../../repositories/course_repository.dart';

class GetCoursesUseCase {
  final CourseRepository repository;

  GetCoursesUseCase(this.repository);

  List<Course> execute() {
    return repository.courses;
  }
}
