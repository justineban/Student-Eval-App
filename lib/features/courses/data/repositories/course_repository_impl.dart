import 'package:proyecto_movil/core/entities/course.dart' as raw;
import '../../domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/local/hive_course_local_data_source.dart';
import '../../../auth/data/datasources/local/hive_auth_local_data_source.dart';

class CourseRepositoryImpl implements CourseRepository {
  final HiveCourseLocalDataSource coursesLocal;
  final HiveAuthLocalDataSource authLocal;
  CourseRepositoryImpl({required this.coursesLocal, required this.authLocal});

  CourseEntity _toDomain(raw.Course c) => CourseEntity(
    id: c.id,
    name: c.name,
    description: c.description,
    teacherId: c.teacherId,
    registrationCode: c.registrationCode,
    studentIds: List<String>.from(c.studentIds),
    invitations: List<String>.from(c.invitations),
  );

  raw.Course _toRaw(CourseEntity c) => raw.Course(
        id: c.id,
        name: c.name,
        description: c.description,
        teacherId: c.teacherId,
        registrationCode: c.registrationCode,
        studentIds: List<String>.from(c.studentIds),
        invitations: List<String>.from(c.invitations),
      );

  @override
  Future<CourseEntity> create(CourseEntity course) async {
    await coursesLocal.putRaw(course.id, _toRaw(course));
    return course;
  }

  @override
  Future<CourseEntity?> getById(String id) async {
    final rawCourse = coursesLocal.getRaw(id) as raw.Course?;
    if (rawCourse == null) return null;
    return _toDomain(rawCourse);
  }

  @override
  Future<CourseEntity?> getByRegistrationCode(String code) async {
    try {
      final rawCourse = coursesLocal.getAllRaw().whereType<raw.Course>().firstWhere((c) => c.registrationCode == code);
      return _toDomain(rawCourse);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(CourseEntity course) async {
    await coursesLocal.putRaw(course.id, _toRaw(course));
  }

  @override
  Future<void> addInvitation(String courseId, String email) async {
    final rawCourse = coursesLocal.getRaw(courseId) as raw.Course?;
    if (rawCourse == null) throw Exception('Curso no encontrado');
    if (!rawCourse.invitations.contains(email)) {
      rawCourse.invitations.add(email);
      await coursesLocal.putRaw(rawCourse.id, rawCourse);
    }
  }

  @override
  Future<void> addStudent(String courseId, String userId) async {
    final rawCourse = coursesLocal.getRaw(courseId) as raw.Course?;
    if (rawCourse == null) throw Exception('Curso no encontrado');
    if (rawCourse.teacherId == userId) return; // docente no se inscribe
    if (!rawCourse.studentIds.contains(userId)) {
      rawCourse.studentIds.add(userId);
      await coursesLocal.putRaw(rawCourse.id, rawCourse);
    }
  }

  @override
  Future<void> removeInvitation(String courseId, String email) async {
    final rawCourse = coursesLocal.getRaw(courseId) as raw.Course?;
    if (rawCourse == null) throw Exception('Curso no encontrado');
    rawCourse.invitations.remove(email);
    await coursesLocal.putRaw(rawCourse.id, rawCourse);
  }

  @override
  Future<List<CourseEntity>> listAll() async => coursesLocal
      .getAllRaw()
      .whereType<raw.Course>()
      .map(_toDomain)
      .toList(growable: false);

  @override
  Future<List<CourseEntity>> listByTeacher(String teacherId) async => coursesLocal
      .getAllRaw()
      .whereType<raw.Course>()
      .where((c) => c.teacherId == teacherId)
      .map(_toDomain)
      .toList(growable: false);

  @override
  Future<List<CourseEntity>> listByStudent(String studentId) async => coursesLocal
      .getAllRaw()
      .whereType<raw.Course>()
      .where((c) => c.studentIds.contains(studentId))
      .map(_toDomain)
      .toList(growable: false);

  @override
  Future<List<CourseEntity>> listByInvitationEmail(String email) async => coursesLocal
      .getAllRaw()
      .whereType<raw.Course>()
      .where((c) => c.invitations.contains(email))
      .map(_toDomain)
      .toList(growable: false);
}
