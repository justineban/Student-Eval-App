import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/student_view/presentation/pages/student_course_detail_page.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final courses = repo.coursesBox.values.where((c) => c.studentIds.contains(user?.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cursos')),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text(course.description),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCourseDetailScreen(courseId: course.id))),
          );
        },
      ),
    );
  }
}
