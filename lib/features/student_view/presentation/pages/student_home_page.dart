import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/core/presentation/widgets/top_bar.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    return Scaffold(
      appBar: TopBar(roleName: 'Estudiante', title: 'Home - Estudiante'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(user != null ? 'Bienvenido, ${user.name}' : 'Bienvenido', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/student/courses'), child: const Text('Mis Cursos')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async { final navigator = Navigator.of(context); await repo.logout(); navigator.pushReplacementNamed('/login'); }, child: const Text('Cerrar sesión')),
          ],
        ),
      ),
    );
  }
}
