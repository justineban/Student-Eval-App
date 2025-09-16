import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'course_detail_page.dart';
import 'package:proyecto_movil/features/teacher_view/presentation/pages/create_course_page.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final myCourses = repo.coursesBox.values.where((c) => c.teacherId == user?.id).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cursos')),
      body: ListView.builder(
        itemCount: myCourses.length,
        itemBuilder: (context, index) {
          final course = myCourses[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text('${course.studentIds.length} estudiantes'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailPage(courseId: course.id))),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCoursePage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
