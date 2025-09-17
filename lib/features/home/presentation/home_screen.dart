import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/create_course_screen.dart';
import 'package:proyecto_movil/features/courses/presentation/teacher_courses_screen.dart';
import 'package:proyecto_movil/features/courses/presentation/enroll_by_code_screen.dart';
import 'package:proyecto_movil/features/courses/presentation/student_courses_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    return Scaffold(
      appBar: TopBar(roleName: user != null && user.email.endsWith('@teacher.com') ? 'Docente' : 'Estudiante', title: 'Home'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
              child: const Text('Crear un curso'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherCoursesScreen())),
              child: const Text('Mis cursos'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollByCodeScreen())),
              child: const Text('Inscribirme a un curso'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentCoursesScreen())),
              child: const Text('Cursos inscritos'),
            ),
          ],
        ),
      ),
    );
  }
}
