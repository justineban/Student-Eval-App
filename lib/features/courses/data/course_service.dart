import '../../../core/entities/course.dart';
import '../../auth/data/auth_service.dart';

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
      teacherId: currentUserId,
      registrationCode: DateTime.now().millisecondsSinceEpoch.toString(),
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
    final courseIndex = userCourses.indexWhere((course) => course.id == courseId);

    if (courseIndex == -1) return false;

    if (!userCourses[courseIndex].studentIds.contains(userId)) {
      userCourses[courseIndex].studentIds.add(userId);
    }
    return true;
  }

  List<Course> getEnrolledCourses(String userId) {
    List<Course> enrolledCourses = [];

    for (var coursesList in _userCourses.values) {
      enrolledCourses.addAll(coursesList.where((course) => course.studentIds.contains(userId)));
    }

    return enrolledCourses;
  }
}
