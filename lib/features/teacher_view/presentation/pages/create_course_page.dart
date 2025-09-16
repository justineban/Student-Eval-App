import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/teacher_view/domain/entities/course.dart';
import 'package:uuid/uuid.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titulo')),
            TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async {
              if (user == null) return;
              final navigator = Navigator.of(context);
              final id = const Uuid().v4();
              final code = id.substring(0, 6);
              final course = Course(id: id, name: _title.text.trim(), description: _desc.text.trim(), teacherId: user.id, registrationCode: code);
              await repo.createCourse(course);
              if (!mounted) return;
              navigator.pop();
            }, child: const Text('Crear')),
          ],
        ),
      ),
    );
  }
}
