import 'package:flutter/material.dart';

class ActivityListPage extends StatelessWidget {
  const ActivityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades')),
      body: const Center(child: Text('Aún no hay actividades')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: abrir creación de actividad (use case futuro)
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
