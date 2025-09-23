import '../../domain/models/course_model.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_local_datasource.dart';
import 'package:uuid/uuid.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseLocalDataSource local;
  final CourseRemoteDataSource? remote; // future remote integration
  final _uuid = const Uuid();

  CourseRepositoryImpl({required this.local, this.remote});

  @override
  Future<CourseModel> createCourse({required String name, required String description, required String teacherId}) async {
    final course = CourseModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      teacherId: teacherId,
      registrationCode: _generateRegistrationCode(),
    );
    // Local-first save. Later: attempt remote, then sync local.
    final saved = await local.saveCourse(course);
    // TODO: enqueue sync task to remote API
    return saved;
  }

  @override
  Future<List<CourseModel>> getCoursesByTeacher(String teacherId) async {
    final localList = await local.fetchCoursesByTeacher(teacherId);
    // TODO: attempt remote fetch & merge if remote available
    return localList;
  }

  String _generateRegistrationCode() {
    return _uuid.v1().substring(0, 6).toUpperCase();
  }
}
