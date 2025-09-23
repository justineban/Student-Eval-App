import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/course.dart';
import 'package:proyecto_movil/core/entities/user.dart';
import 'package:proyecto_movil/features/category/presentation/categories_list_screen.dart'
    as teacher_categories;
import 'package:proyecto_movil/features/activities/presentation/course_activities_screen.dart';

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
            Text(
              course.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Docente: $teacherName', style: const TextStyle(fontSize: 16)),
            if (isCreator) ...[
              const SizedBox(height: 4),
              Text(
                'Código de inscripción: $code',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar curso'),
                        content: const Text(
                          'Esta acción eliminará también categorías y grupos asociados. ¿Continuar?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await repo.deleteCourse(course.id);
                      if (context.mounted) {
                        Navigator.pop(context, true); // indicar cambio
                      }
                    }
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Eliminar curso',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Sección lista de estudiantes
            const Text(
              'Lista de estudiantes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => teacher_categories.CategoriesListScreen(
                          courseId: course.id,
                          canCreate: isCreator,
                        ),
                      ),
                    );
                  },
                  child: const Text('Ver Categorías'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseActivitiesScreen(courseId: course.id),
                      ),
                    );
                  },
                  child: const Text('Ver Actividades'),
                ),
              ],
            ),
            // Sección de invitación (solo para el docente)
            if (isCreator) ...[
              const SizedBox(height: 16),
              const Text(
                'Invitar estudiante',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inviteController,
                      decoration: const InputDecoration(
                        hintText: 'Correo del estudiante',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
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
