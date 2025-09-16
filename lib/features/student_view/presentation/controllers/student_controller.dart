import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/teacher_view/domain/entities/course.dart';

class StudentController extends ChangeNotifier {
  final LocalRepository repo;
  StudentController(this.repo);

  List<Course> myCourses() {
    final user = repo.currentUser;
    return repo.coursesBox.values.where((c) => c.studentIds.contains(user?.id)).toList();
  }

  Course? getCourse(String id) => repo.getCourse(id);
}
