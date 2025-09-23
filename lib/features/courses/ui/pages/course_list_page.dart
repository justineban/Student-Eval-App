// Course list page (enabled navigation to local detail; no external data layer)
import 'package:flutter/material.dart';
import '../../domain/models/course_model.dart';
import 'course_detail_page.dart';
import 'add_course_page.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});
  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  final List<CourseModel> _sample = List.generate(
    5,
    (i) => CourseModel(
      id: 'c$i',
      name: 'Curso $i',
      description: 'Descripción del curso $i',
      teacherId: 't1',
      registrationCode: 'CODE$i',
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cursos')),
        body: ListView.separated(
          itemCount: _sample.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final course = _sample[index];
            return ListTile(
              title: Text(course.name),
              subtitle: Text(course.description),
              trailing: Text('${course.studentIds.length} usuarios'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailPageVisual(course: course),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCoursePage()),
            );
          },
          child: const Icon(Icons.add),
        ),
      );
}
