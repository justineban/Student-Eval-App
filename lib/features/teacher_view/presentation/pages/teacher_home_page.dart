import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/core/presentation/widgets/top_bar.dart';
import 'package:proyecto_movil/features/teacher_view/presentation/pages/create_course_page.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    return Scaffold(
      appBar: TopBar(roleName: 'Docente', title: 'Home - Docente'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(user != null ? 'Bienvenido, ${user.name}' : 'Bienvenido', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/teacher/courses'), child: const Text('Mis Cursos')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCoursePage())),
              child: const Text('Crear Curso'),
            ),
            // logout button removed for teacher home (logout remains available via top bar)
          ],
        ),
      ),
    );
  }
}
