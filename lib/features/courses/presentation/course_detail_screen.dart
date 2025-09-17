import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/course.dart';
import 'package:proyecto_movil/core/entities/user.dart';
import 'package:proyecto_movil/features/category/presentation/categories_list_screen.dart' as teacher_categories;

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
  final isCreator = user != null && user.id == course.teacherId;
  final students = repo.listStudentsForCourse(course.id);
  final teacher = repo.usersBox.get(course.teacherId);
  final teacherName = teacher?.name ?? 'Desconocido';
  final code = course.registrationCode;
  final TextEditingController inviteController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección superior
            Text(course.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Docente: $teacherName', style: const TextStyle(fontSize: 16)),
            if (isCreator) ...[
              const SizedBox(height: 4),
              Text('Código de inscripción: $code', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
            const SizedBox(height: 24),
            // Sección lista de estudiantes
            const Text('Lista de estudiantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final User student = students[index];
                    return ListTile(
                      title: Text(student.name),
                      subtitle: Text(student.email),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => teacher_categories.CategoriesListScreen(
                      courseId: course.id,
                      canCreate: isCreator,
                    ),
                  ),
                ),
                child: const Text('Ver Categorías'),
              ),
            ),
            // Sección de invitación (solo para el docente)
            if (isCreator) ...[
              const SizedBox(height: 16),
              const Text('Invitar estudiante', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inviteController,
                      decoration: const InputDecoration(hintText: 'Correo del estudiante'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Lógica para enviar invitación
                    },
                    child: const Text('Enviar invitación'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
