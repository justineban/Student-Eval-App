import 'package:flutter/material.dart';
import '../data/course_service.dart';
import '../../auth/data/auth_service.dart';
import 'course_detail_screen.dart';

class EnrolledCoursesScreen extends StatelessWidget {
  const EnrolledCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario conectado')),
      );
    }

    final enrolledCourses = CourseService().getEnrolledCourses(currentUser.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cursos Inscritos')),
      body: ListView.builder(
        itemCount: enrolledCourses.length,
        itemBuilder: (context, index) {
          final course = enrolledCourses[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text(course.description),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailScreen(course: course),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
