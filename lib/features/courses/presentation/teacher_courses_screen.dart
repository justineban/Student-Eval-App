import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/local_repository.dart';
import '../../../../core/widgets/top_bar.dart';
import 'create_course_screen.dart';
import 'course_detail_screen.dart';

class TeacherCoursesScreen extends StatelessWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final myCourses = repo.coursesBox.values.where((c) => c.teacherId == user?.id).toList();

    return Scaffold(
      appBar: const TopBar(roleName: 'Docente', title: 'Mis Cursos'),
      body: ListView.builder(
        itemCount: myCourses.length,
        itemBuilder: (context, index) {
          final course = myCourses[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text('${course.studentIds.length} estudiantes'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course))),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
