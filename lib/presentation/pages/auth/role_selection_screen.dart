import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository_impl.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final current = AuthRepositoryImpl().currentRole;
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Rol')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rol actual: ${current ?? "no seleccionado"}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                AuthRepositoryImpl().setRole('student');
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Entrar como Estudiante'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                AuthRepositoryImpl().setRole('teacher');
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Entrar como Profesor'),
            ),
          ],
        ),
      ),
    );
  }
}
