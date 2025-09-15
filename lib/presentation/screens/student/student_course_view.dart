import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import '../../widgets/top_bar.dart';
import '../teacher/categories_list_screen.dart' as teacher_categories;

class StudentCourseView extends StatelessWidget {
  final String courseId;
  const StudentCourseView({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final course = repo.getCourse(courseId);
    if (course == null) return Scaffold(body: Center(child: Text('Curso no encontrado')));
    final teacher = repo.usersBox.get(course.teacherId);
    final students = repo.listStudentsForCourse(courseId);

    return Scaffold(
      appBar: TopBar(roleName: 'Estudiante', title: course.name),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Docente: ${teacher?.name ?? 'Desconocido'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Curso: ${course.name}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Estudiantes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  return ListTile(title: Text(s.name), subtitle: Text(s.email));
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => teacher_categories.CategoriesListScreen(courseId: courseId, canCreate: false))),
              child: const Text('Ver Categorías'),
            ),
          ],
        ),
      ),
    );
  }
}
