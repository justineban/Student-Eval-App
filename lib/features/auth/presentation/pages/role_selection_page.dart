import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar rol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/teacher/home'), child: const Text('Docente')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/student/home'), child: const Text('Estudiante')),
          ],
        ),
      ),
    );
  }
}
