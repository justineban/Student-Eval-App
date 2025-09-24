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

  @override
  Future<CourseModel?> getCourseById(String id) async {
    return await local.fetchCourseById(id);
  }

  @override
  Future<CourseModel> inviteStudent({required String courseId, required String teacherId, required String email}) async {
    final course = await local.fetchCourseById(courseId);
    if (course == null) {
      throw Exception('Curso no encontrado');
    }
    if (course.teacherId != teacherId) {
      throw Exception('No autorizado');
    }
    if (email.trim().isEmpty) {
      throw Exception('Email requerido');
    }
    // evitar duplicados
    if (!course.invitations.contains(email)) {
      course.invitations.add(email);
      await local.updateCourse(course);
      // TODO: remote sync invitation
    }
    return course;
  }

  String _generateRegistrationCode() {
    return _uuid.v1().substring(0, 6).toUpperCase();
  }

  @override
  Future<CourseModel> updateCourse({required String id, required String name, required String description, required String teacherId}) async {
    final existing = await local.fetchCourseById(id);
    if (existing == null) throw Exception('Curso no encontrado');
    if (existing.teacherId != teacherId) throw Exception('No autorizado');
    existing.name = name;
    existing.description = description;
    final saved = await local.updateCourse(existing);
    return saved;
  }

  @override
  Future<void> deleteCourse({required String id, required String teacherId}) async {
    final existing = await local.fetchCourseById(id);
    if (existing == null) return;
    if (existing.teacherId != teacherId) throw Exception('No autorizado');
    await local.deleteCourse(id);
  }
}
