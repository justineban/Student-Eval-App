import 'package:flutter/material.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (AuthService().currentRole != 'teacher') {
      return Scaffold(
        appBar: AppBar(title: const Text('Agregar Curso')),
        body: const Center(child: Text('Solo los profesores pueden crear cursos')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del curso',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del curso';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCourse,
                child: const Text('Guardar Curso'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      final course = await CourseService().addCourse(
        _nameController.text,
        _descriptionController.text,
      );
      if (!mounted) return;
      // show registration code
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Curso creado'),
          content: Text('Código de registro: ${course.registrationCode}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
