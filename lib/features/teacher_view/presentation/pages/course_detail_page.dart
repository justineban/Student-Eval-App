import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/teacher_view/presentation/pages/category_pages.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final _inviteController = TextEditingController();

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final course = repo.getCourse(widget.courseId);
    if (course == null) {
      return Scaffold(appBar: AppBar(title: const Text('Detalles del curso')), body: const Center(child: Text('Curso no encontrado')));
    }

    final teacher = repo.usersBox.get(course.teacherId);
    final students = repo.listStudentsForCourse(course.id);

    return Scaffold(
      appBar: AppBar(title: Text(course.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profesor: ${teacher?.name ?? 'Desconocido'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Código de registro: ${course.registrationCode}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryListPage(courseId: course.id)));
              },
              child: const Text('Ver Categorías'),
            ),
            const SizedBox(height: 12),
            const Text('Estudiantes inscritos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  return ListTile(title: Text(s.name), subtitle: Text(s.email));
                },
              ),
            ),
            const Divider(),
            const Text('Invitar estudiante por correo', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: TextField(controller: _inviteController, decoration: const InputDecoration(hintText: 'correo@ejemplo.com'))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final email = _inviteController.text.trim();
                    if (email.isEmpty) return;
                    final success = await repo.inviteByEmail(course.id, email);
                    if (!mounted) return;
                    if (success) {
                      _inviteController.clear();
                      messenger.showSnackBar(const SnackBar(content: Text('Invitación enviada')));
                      setState(() {});
                    } else {
                      messenger.showSnackBar(const SnackBar(content: Text('Fallo al invitar')));
                    }
                  },
                  child: const Text('Invitar'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
