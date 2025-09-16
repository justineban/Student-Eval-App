import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/student_view/presentation/pages/student_category_list_page.dart';

class StudentCourseDetailScreen extends StatelessWidget {
  final String courseId;
  const StudentCourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final course = repo.getCourse(courseId);
    final teacher = course != null ? repo.usersBox.get(course.teacherId) : null;
    final students = course != null ? repo.listStudentsForCourse(course.id) : [];

    return Scaffold(
      appBar: AppBar(title: Text(course?.name ?? 'Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar nombre del docente
            Text('Docente: ${teacher?.name ?? 'Desconocido'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            // Texto 'Lista de Estudiantes'
            const Text('Lista de Estudiantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            // Scrollbar que despliega la lista de estudiantes
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      title: Text(student.name),
                      subtitle: Text(student.email),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botón de ver categorías (vista de estudiante, sin opciones de crear, editar o borrar)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCategoryListPage(courseId: course!.id)));
                },
                child: const Text('Ver Categorías'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
