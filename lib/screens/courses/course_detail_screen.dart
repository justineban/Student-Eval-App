import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final course = CourseService().getCourse(widget.courseId);

    if (course == null) {
      return const Scaffold(body: Center(child: Text('Curso no encontrado')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(course.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción:', style: Theme.of(context).textTheme.titleLarge),
            Text(course.description),
            const SizedBox(height: 20),
            Text(
              'Usuarios Inscritos:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: course.enrolledUserIds.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Usuario ${course.enrolledUserIds[index]}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentUser = AuthService().currentUser;
          if (currentUser != null) {
            await CourseService().enrollUser(course.id, currentUser.id);
            setState(() {});
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
