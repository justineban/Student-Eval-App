import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import '../../../domain/entities/course.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/top_bar.dart';
import 'course_detail_screen.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    return Scaffold(
      appBar: const TopBar(roleName: 'Docente', title: 'Crear Curso'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (user == null) return;
                final navigator = Navigator.of(context);
                final id = const Uuid().v4();
                final code = id.substring(0, 6);
                final course = Course(id: id, name: _name.text.trim(), description: _desc.text.trim(), teacherId: user.id, registrationCode: code);
                final created = await repo.createCourse(course);
                if (!mounted) return;
                // Open the created course view
                navigator.pushReplacement(MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: created.id)));
              },
              child: const Text('Crear'),
            )
          ],
        ),
      ),
    );
  }
}
