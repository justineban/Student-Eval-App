import '../../domain/models/course.dart';
import 'auth_repository_impl.dart';
import '../../domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements CourseRepository {
  static final CourseRepositoryImpl _instance =
      CourseRepositoryImpl._internal();
  factory CourseRepositoryImpl() => _instance;
  CourseRepositoryImpl._internal() {
    seedTestData();
  }

  final Map<String, List<Course>> _userCourses = {};

  @override
  List<Course> get courses {
    final currentUserId = AuthRepositoryImpl().currentUser?.id;
    if (currentUserId == null) return [];
    return List.unmodifiable(_userCourses[currentUserId] ?? []);
  }

  /// Returns a list of all courses across all owners.
  @override
  List<Course> getAllCourses() {
    final all = <Course>[];
    for (var list in _userCourses.values) {
      all.addAll(list);
    }
    return List.unmodifiable(all);
  }

  @override
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
  @override
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

  @override
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

  @override
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

  @override
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
  @override
  int countCoursesForUser(String userId) {
    return getEnrolledCourses(userId).length;
  }

  void seedTestData() {
    final test1 = AuthRepositoryImpl().users.firstWhere((u) => u.email == 'a@a.com');
    final test2 = AuthRepositoryImpl().users.firstWhere((u) => u.email == 'b@a.com');

    final curso1 = Course(
      id: 'curso1',
      name: 'curso1',
      description: 'Test course 1',
      ownerId: test1.id,
      ownerName: test1.name,
      registrationCode: 'CURSO1CODE',
    );

    _userCourses[test1.id] = [curso1];
    curso1.enrolledUserIds.add(test2.id);
  }
}
