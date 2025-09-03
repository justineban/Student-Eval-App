import '../models/course.dart';
import 'auth_service.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final Map<String, List<Course>> _userCourses = {};

  List<Course> get courses {
    final currentUserId = AuthService().currentUser?.id;
    if (currentUserId == null) return [];
    return List.unmodifiable(_userCourses[currentUserId] ?? []);
  }

  Future<Course> addCourse(String name, String description) async {
    final currentUserId = AuthService().currentUser?.id;
    if (currentUserId == null) throw Exception('No hay usuario conectado');

    final course = Course(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );

    _userCourses[currentUserId] ??= [];
    _userCourses[currentUserId]!.add(course);

    return course;
  }

  Course? getCourse(String id) {
    final currentUserId = AuthService().currentUser?.id;
    if (currentUserId == null) return null;

    final userCourses = _userCourses[currentUserId] ?? [];
    try {
      return userCourses.firstWhere((course) => course.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> enrollUser(String courseId, String userId) async {
    final currentUserId = AuthService().currentUser?.id;
    if (currentUserId == null) return false;

    final userCourses = _userCourses[currentUserId] ?? [];
    final courseIndex = userCourses.indexWhere(
      (course) => course.id == courseId,
    );

    if (courseIndex == -1) return false;

    if (!userCourses[courseIndex].enrolledUserIds.contains(userId)) {
      userCourses[courseIndex].enrolledUserIds.add(userId);
    }
    return true;
  }

  List<Course> getEnrolledCourses(String userId) {
    List<Course> enrolledCourses = [];

    _userCourses.values.forEach((coursesList) {
      enrolledCourses.addAll(
        coursesList.where((course) => course.enrolledUserIds.contains(userId)),
      );
    });

    return enrolledCourses;
  }
}
