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
    // Try remote first so IDs stay consistent with server, then persist locally
    if (remote != null) {
      try {
        final created = await remote!.createRemoteCourse(name: name, description: description, teacherId: teacherId);
        // ignore: avoid_print
        print('[CourseRepository] Remote create success id=${created.id}');
        await local.saveCourse(created);
        return created;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote create failed, falling back to local. Error: $e');
      }
    }
    // Fallback: create locally
    final localCourse = CourseModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      teacherId: teacherId,
      registrationCode: _generateRegistrationCode(),
    );
    return await local.saveCourse(localCourse);
  }

  @override
  Future<List<CourseModel>> getCoursesByTeacher(String teacherId) async {
    // Try remote; if available, sync locally and return remote data
    if (remote != null) {
      try {
        final remoteList = await remote!.fetchRemoteCoursesByTeacher(teacherId);
        // simple sync: upsert each remote course locally
        for (final c in remoteList) {
          await local.saveCourse(c);
        }
        // ignore: avoid_print
        print('[CourseRepository] Remote fetch returned ${remoteList.length} courses for teacher=$teacherId');
        return remoteList;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote fetch failed, falling back to local. Error: $e');
      }
    }
    return await local.fetchCoursesByTeacher(teacherId);
  }

  @override
  Future<CourseModel?> getCourseById(String id) async {
    if (remote != null) {
      try {
        final r = await remote!.fetchRemoteCourseById(id);
        if (r != null) await local.saveCourse(r);
        return r ?? await local.fetchCourseById(id);
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote getById failed, using local. Error: $e');
      }
    }
    return await local.fetchCourseById(id);
  }

  @override
  Future<CourseModel> inviteStudent({required String courseId, required String teacherId, required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Email requerido');
    }
    // Remote-first to keep server as source of truth
    if (remote != null) {
      try {
        // Fetch current from remote (ensures we validate teacherId from server state)
        final remoteCourse = await remote!.fetchRemoteCourseById(courseId);
        if (remoteCourse == null) throw Exception('Curso no encontrado');
        if (remoteCourse.teacherId != teacherId) throw Exception('No autorizado');
        if (!remoteCourse.invitations.contains(normalized)) {
          final updatedInvites = List<String>.from(remoteCourse.invitations)..add(normalized);
          final updated = await remote!.updateRemoteCourse(id: courseId, updates: {
            'invitations': updatedInvites,
          });
          await local.saveCourse(updated);
          // ignore: avoid_print
          print('[CourseRepository] inviteStudent remote updated invitations for course=$courseId');
          return updated;
        }
        await local.saveCourse(remoteCourse);
        return remoteCourse;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] inviteStudent remote failed, falling back to local. Error: $e');
      }
    }
    // Local fallback
    final course = await local.fetchCourseById(courseId);
    if (course == null) throw Exception('Curso no encontrado');
    if (course.teacherId != teacherId) throw Exception('No autorizado');
    if (!course.invitations.contains(normalized)) {
      course.invitations.add(normalized);
      await local.updateCourse(course);
    }
    return course;
  }

  String _generateRegistrationCode() {
    return _uuid.v1().substring(0, 6).toUpperCase();
  }

  @override
  Future<CourseModel> updateCourse({required String id, required String name, required String description, required String teacherId}) async {
    // Remote first to ensure source of truth
    if (remote != null) {
      try {
        final updated = await remote!.updateRemoteCourse(
          id: id,
          updates: {
            'name': name,
            'description': description,
          },
        );
        await local.saveCourse(updated);
        return updated;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote update failed, trying local. Error: $e');
      }
    }
    final existing = await local.fetchCourseById(id);
    if (existing == null) throw Exception('Curso no encontrado');
    if (existing.teacherId != teacherId) throw Exception('No autorizado');
    existing.name = name;
    existing.description = description;
    return await local.updateCourse(existing);
  }

  @override
  Future<void> deleteCourse({required String id, required String teacherId}) async {
    if (remote != null) {
      try {
        await remote!.deleteRemoteCourse(id);
        await local.deleteCourse(id);
        return;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote delete failed, deleting local. Error: $e');
      }
    }
    final existing = await local.fetchCourseById(id);
    if (existing == null) return;
    if (existing.teacherId != teacherId) throw Exception('No autorizado');
    await local.deleteCourse(id);
  }

  // Student-side operations
  @override
  Future<CourseModel?> getCourseByRegistrationCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (remote != null) {
      try {
        final r = await remote!.fetchRemoteCourseByRegistrationCode(normalized);
        if (r != null) await local.saveCourse(r);
        return r ?? await local.fetchCourseByRegistrationCode(normalized);
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote getByCode failed, using local. Error: $e');
      }
    }
    return await local.fetchCourseByRegistrationCode(normalized);
  }

  @override
  Future<CourseModel?> joinCourseByCode({required String code, required String studentId}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    if (remote != null) {
      try {
        final course = await remote!.fetchRemoteCourseByRegistrationCode(normalized);
        if (course == null) return null;
        if (!course.studentIds.contains(studentId)) {
          final updatedStudents = List<String>.from(course.studentIds)..add(studentId);
          final updated = await remote!.updateRemoteCourse(id: course.id, updates: {
            'studentIds': updatedStudents,
          });
          await local.saveCourse(updated);
          // ignore: avoid_print
          print('[CourseRepository] joinCourseByCode remote updated students for course=${course.id}');
          return updated;
        }
        await local.saveCourse(course);
        return course;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] joinCourseByCode remote failed, using local. Error: $e');
      }
    }
    // Local fallback
    final course = await local.fetchCourseByRegistrationCode(normalized);
    if (course == null) return null;
    if (!course.studentIds.contains(studentId)) {
      course.studentIds.add(studentId);
      await local.updateCourse(course);
    }
    return course;
  }

  @override
  Future<List<CourseModel>> getCoursesByStudent(String studentId) async {
    if (remote != null) {
      try {
        final list = await remote!.fetchRemoteCoursesByStudent(studentId);
        for (final c in list) {
          await local.saveCourse(c);
        }
        return list;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote getByStudent failed, using local. Error: $e');
      }
    }
    return await local.fetchCoursesByStudent(studentId);
  }

  @override
  Future<List<CourseModel>> getInvitedCoursesForEmail(String email) async {
    final norm = email.trim().toLowerCase();
    if (remote != null) {
      try {
        final list = await remote!.fetchRemoteInvitedCoursesForEmail(norm);
        for (final c in list) {
          await local.saveCourse(c);
        }
        return list;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] Remote invitedCourses failed, using local. Error: $e');
      }
    }
    return await local.fetchInvitedCoursesForEmail(norm);
  }

  @override
  Future<CourseModel?> acceptInvitation({required String courseId, required String email, required String studentId}) async {
    final emailNorm = email.trim().toLowerCase();
    if (remote != null) {
      try {
        final course = await remote!.fetchRemoteCourseById(courseId);
        if (course == null) return null;
        final newInvites = List<String>.from(course.invitations)..remove(emailNorm);
        final newStudents = course.studentIds.contains(studentId)
            ? List<String>.from(course.studentIds)
            : (List<String>.from(course.studentIds)..add(studentId));
        final updated = await remote!.updateRemoteCourse(id: courseId, updates: {
          'invitations': newInvites,
          'studentIds': newStudents,
        });
        await local.saveCourse(updated);
        // ignore: avoid_print
        print('[CourseRepository] acceptInvitation remote updated course=$courseId');
        return updated;
      } catch (e) {
        // ignore: avoid_print
        print('[CourseRepository] acceptInvitation remote failed, using local. Error: $e');
      }
    }
    // Local fallback
    final course = await local.fetchCourseById(courseId);
    if (course == null) return null;
    if (course.invitations.contains(emailNorm)) {
      course.invitations.remove(emailNorm);
    }
    if (!course.studentIds.contains(studentId)) {
      course.studentIds.add(studentId);
    }
    await local.updateCourse(course);
    return course;
  }
}
