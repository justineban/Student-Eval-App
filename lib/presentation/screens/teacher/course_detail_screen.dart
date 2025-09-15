import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import 'categories_list_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _inviteEmail = TextEditingController();

  @override
  void dispose() {
    _inviteEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final course = repo.getCourse(widget.courseId);
    if (course == null) return Scaffold(body: Center(child: Text('Curso no encontrado')));

    final students = repo.listStudentsForCourse(course.id);

    return Scaffold(
      appBar: AppBar(title: Text(course.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código de registro: ${course.registrationCode}'),
            const SizedBox(height: 8),
            Text('Estudiantes inscritos: ${course.studentIds.length}'),
            const SizedBox(height: 12),
            TextField(controller: _inviteEmail, decoration: const InputDecoration(labelText: 'Invitar por correo')),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final email = _inviteEmail.text.trim();
                    await repo.inviteByEmail(course.id, email);
                    _inviteEmail.clear();
                    messenger.showSnackBar(const SnackBar(content: Text('Invitación enviada')));
                  },
                  child: const Text('Invitar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesListScreen(courseId: course.id))), child: const Text('Ver Categorías')),
            const SizedBox(height: 12),
            const Text('Lista de estudiantes:'),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  return ListTile(title: Text(s.name), subtitle: Text(s.email));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
