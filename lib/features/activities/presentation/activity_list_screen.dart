import 'package:flutter/material.dart';
import '../controllers/activities_controller.dart';
import '../domain/activity_entity.dart';

/// Pantalla simple para listar activities por curso.
class ActivityListScreen extends StatefulWidget {
  final String courseId;
  final String categoryId;
  const ActivityListScreen({
    super.key,
    required this.courseId,
    required this.categoryId,
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  late final ActivitiesController controller;

  @override
  void initState() {
    super.initState();
    controller = ActivitiesController();
    controller.addListener(_onChange);
    // Deprecated: ahora las actividades se muestran por categoría
    controller.loadByCategory(widget.categoryId);
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades')),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: controller.categoryActivities.length,
              itemBuilder: (context, index) {
                final Activity a = controller.categoryActivities[index];
                return ListTile(
                  title: Text(a.title),
                  subtitle: Text(a.description),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final now = DateTime.now();
          await controller.createActivity(
            courseId: widget.courseId,
            categoryId: widget.categoryId,
            title: 'Nueva actividad ${now.millisecondsSinceEpoch}',
            description: 'Descripción generada',
            dueDate: now.add(const Duration(days: 7)),
          );
          controller.loadByCategory(widget.categoryId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
