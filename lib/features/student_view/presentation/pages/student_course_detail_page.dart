import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:provider/provider.dart';

class StudentCourseDetailScreen extends StatelessWidget {
  final String courseId;
  const StudentCourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
  final course = repo.getCourse(courseId);
    return Scaffold(
      appBar: AppBar(title: Text(course?.name ?? 'Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course?.name ?? ''),
            const SizedBox(height: 8),
            Text(course?.description ?? ''),
          ],
        ),
      ),
    );
  }
}
