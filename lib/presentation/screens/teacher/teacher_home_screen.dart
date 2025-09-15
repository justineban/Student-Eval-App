import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import '../../widgets/top_bar.dart';
import 'create_course_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
              child: const Text('Crear Curso'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async { final navigator = Navigator.of(context); await repo.logout(); navigator.pushReplacementNamed('/login'); }, child: const Text('Cerrar sesión')),
          ],
        ),
      ),
    );
  }
}
