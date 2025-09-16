import 'package:proyecto_movil/features/teacher_view/domain/entities/course.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final Map<String, List<Course>> _userCourses = {};

  List<Course> get courses {
    return _userCourses.values.expand((c) => c).toList();
  }

  Future<Course> addCourse(String name, String description) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final course = Course(
      id: id,
      name: name,
      description: description,
      teacherId: 'teacher_$id',
      registrationCode: id.substring(id.length - 6),
    );

    // For simplicity store under a synthetic key
    _userCourses['default'] ??= [];
    _userCourses['default']!.add(course);

    return course;
  }

  Course? getCourse(String id) {
    try {
      return _userCourses.values.expand((c) => c).firstWhere((course) => course.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> enrollUser(String courseId, String userId) async {
    for (final list in _userCourses.values) {
      final idx = list.indexWhere((c) => c.id == courseId);
      if (idx != -1) {
        final course = list[idx];
        if (!course.studentIds.contains(userId)) course.studentIds.add(userId);
        return true;
      }
    }
    return false;
  }

  List<Course> getEnrolledCourses(String userId) {
    final enrolled = <Course>[];
    for (final list in _userCourses.values) {
      enrolled.addAll(list.where((c) => c.studentIds.contains(userId)));
    }
    return enrolled;
  }
}
