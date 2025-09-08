import 'package:flutter/material.dart';
import '../../services/course_service.dart';

class UserCoursesScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const UserCoursesScreen({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    final courses = CourseService().getEnrolledCourses(userId);
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
