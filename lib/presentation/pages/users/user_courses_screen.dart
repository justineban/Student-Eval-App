import 'package:flutter/material.dart';
import '../../../data/repositories/course_repository_impl.dart';

class UserCoursesScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const UserCoursesScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final courses = CourseRepositoryImpl().getEnrolledCourses(userId);
    return Scaffold(
      appBar: AppBar(title: Text('Cursos de $userName')),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text(course.description),
          );
        },
      ),
    );
  }
}
