import 'package:flutter/material.dart';
import '../data/course_service.dart';
import '../../../core/entities/course.dart';

class CoursesController with ChangeNotifier {
  final CourseService _courseService = CourseService();

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  List<Course> get courses => _courseService.courses;

  Future<Course?> addCourse(String name, String description) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final course = await _courseService.addCourse(name, description);
      _loading = false;
      notifyListeners();
      return course;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Course? getCourse(String id) {
    return _courseService.getCourse(id);
  }

  Future<bool> enrollUser(String courseId, String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _courseService.enrollUser(courseId, userId);
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Course> getEnrolledCourses(String userId) {
    return _courseService.getEnrolledCourses(userId);
  }
}
