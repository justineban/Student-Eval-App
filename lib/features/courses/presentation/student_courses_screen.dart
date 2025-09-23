import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/course.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/course_detail_screen.dart';

class StudentCoursesScreen extends StatelessWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('No user')));
    final myCourses = repo.coursesBox.values
        .where((c) => c.studentIds.contains(user.id))
        .toList();
    return Scaffold(
      appBar: const TopBar(title: 'Mis Cursos'),
      body: ListView.builder(
        itemCount: myCourses.length,
        itemBuilder: (context, index) {
          final Course c = myCourses[index];
          return ListTile(
            title: Text(c.name),
            subtitle: Text(
              'Docente: ${repo.usersBox.get(c.teacherId)?.name ?? '---'}',
            ),
            onTap: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(course: c),
                ),
              );
              if (changed == true) {
                // Si el curso se eliminó, la lista se actualizará porque el provider ya notificó
              }
            },
          );
        },
      ),
    );
  }
}
