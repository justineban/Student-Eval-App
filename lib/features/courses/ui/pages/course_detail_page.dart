// Course detail page (no-op actions enabled)
import 'package:flutter/material.dart';
import '../../domain/models/course_model.dart';

class CourseDetailPageVisual extends StatelessWidget {
  final CourseModel course;
  const CourseDetailPageVisual({super.key, required this.course});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detalle Curso')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(course.description),
              const SizedBox(height: 16),
              Text('Código: ${course.registrationCode}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Editar')), // no-op
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: () {}, child: const Text('Eliminar')), // no-op
                ],
              ),
              const SizedBox(height: 24),
              const Text('Estudiantes (placeholder)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: course.studentIds.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text('Student ${course.studentIds[i]}'),
                    trailing: IconButton(
                      onPressed: () {}, // no-op
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Acciones habilitadas sin implementación (no-op).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}
