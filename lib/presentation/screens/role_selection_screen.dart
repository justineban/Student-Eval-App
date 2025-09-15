import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Rol')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/teacher/home'), child: const Text('Ingresar como Docente')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/student/home'), child: const Text('Ingresar como Estudiante')),
          ],
        ),
      ),
    );
  }
}
