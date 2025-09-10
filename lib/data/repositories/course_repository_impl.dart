import '../../domain/models/course.dart';
import 'auth_repository_impl.dart';
import '../../domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements CourseRepository {
  static final CourseRepositoryImpl _instance =
      CourseRepositoryImpl._internal();
  factory CourseRepositoryImpl() => _instance;
  CourseRepositoryImpl._internal();

  final Map<String, List<Course>> _userCourses = {};

  List<Course> get courses {
    final currentUserId = AuthRepositoryImpl().currentUser?.id;
    if (currentUserId == null) return [];
    return List.unmodifiable(_userCourses[currentUserId] ?? []);
  }

  /// Returns a list of all courses across all owners.
  List<Course> getAllCourses() {
    final all = <Course>[];
    for (var list in _userCourses.values) {
      all.addAll(list);
    }
    return List.unmodifiable(all);
  }

  Future<Course> addCourse(String name, String description) async {
    final currentUserId = AuthRepositoryImpl().currentUser?.id;
    if (currentUserId == null) throw Exception('No hay usuario conectado');

    final owner = AuthRepositoryImpl().currentUser!;
    final code = DateTime.now().millisecondsSinceEpoch.toRadixString(36);

    final course = Course(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      ownerId: owner.id,
      ownerName: owner.name,
      registrationCode: code,
    );

    _userCourses[currentUserId] ??= [];
    _userCourses[currentUserId]!.add(course);

    return course;
  }

  /// Enroll a user using the course registration code.
  Future<bool> enrollByCode(String registrationCode, String userId) async {
    for (var coursesList in _userCourses.values) {
      final index = coursesList.indexWhere(
        (c) => c.registrationCode == registrationCode,
      );
      if (index != -1) {
        final course = coursesList[index];
        if (!course.enrolledUserIds.contains(userId)) {
          course.enrolledUserIds.add(userId);
        }
        return true;
      }
    }
    return false;
  }

  Course? getCourse(String id) {
    for (var coursesList in _userCourses.values) {
      try {
        final found = coursesList.firstWhere((course) => course.id == id);
        return found;
      } catch (e) {
        // not found in this list, continue
      }
    }
    return null;
  }

  Future<bool> enrollUser(String courseId, String userId) async {
    for (var coursesList in _userCourses.values) {
      final index = coursesList.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        final course = coursesList[index];
        if (!course.enrolledUserIds.contains(userId)) {
          course.enrolledUserIds.add(userId);
        }
        return true;
      }
    }
    return false;
  }

  List<Course> getEnrolledCourses(String userId) {
    List<Course> enrolledCourses = [];

    for (var coursesList in _userCourses.values) {
      enrolledCourses.addAll(
        coursesList.where((course) => course.enrolledUserIds.contains(userId)),
      );
    }

    return enrolledCourses;
  }

  /// Returns how many courses a user is enrolled in across all owners
  int countCoursesForUser(String userId) {
    return getEnrolledCourses(userId).length;
  }
}
