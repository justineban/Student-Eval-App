import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import '../../../domain/entities/course.dart';
import '../../widgets/top_bar.dart';
import 'student_course_view.dart';

class StudentCoursesScreen extends StatelessWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('No user')));
    final myCourses = repo.coursesBox.values.where((c) => c.studentIds.contains(user.id)).toList();
    return Scaffold(
  appBar: TopBar(roleName: 'Estudiante', title: 'Mis Cursos'),
      body: ListView.builder(
        itemCount: myCourses.length,
        itemBuilder: (context, index) {
          final Course c = myCourses[index];
          return ListTile(
            title: Text(c.name),
            subtitle: Text('Docente: ${repo.usersBox.get(c.teacherId)?.name ?? '---'}'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCourseView(courseId: c.id))),
          );
        },
      ),
    );
  }
}
