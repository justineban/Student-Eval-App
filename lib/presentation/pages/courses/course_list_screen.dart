import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/course_repository_impl.dart';
import 'add_course_screen.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  @override
  Widget build(BuildContext context) {
    final role = AuthRepositoryImpl().currentRole;
    final courses = role == 'teacher'
        ? CourseRepositoryImpl().courses
        : CourseRepositoryImpl().getAllCourses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthRepositoryImpl().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text(course.description),
            trailing: Text('${course.enrolledUserIds.length} usuarios'),
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(courseId: course.id),
                ),
              );
              setState(() {});
            },
          );
        },
      ),
      floatingActionButton: role == 'teacher'
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCourseScreen()),
                );
                setState(() {});
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
