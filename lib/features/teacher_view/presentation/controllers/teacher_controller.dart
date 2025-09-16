import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/teacher_view/domain/entities/course.dart';

class TeacherController extends ChangeNotifier {
  final LocalRepository repo;
  TeacherController(this.repo);

  List<Course> myCourses() {
    final user = repo.currentUser;
    return repo.coursesBox.values.where((c) => c.teacherId == user?.id).toList();
  }

  Future<Course> createCourse(Course course) => repo.createCourse(course);
}
