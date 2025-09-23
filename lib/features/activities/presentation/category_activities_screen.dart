import 'package:flutter/material.dart';
import '../controllers/activities_controller.dart';
import '../domain/activity_entity.dart';
import '../domain/assessment_entity.dart';

class CategoryActivitiesScreen extends StatefulWidget {
  final String courseId;
  final String categoryId;
  const CategoryActivitiesScreen({
    super.key,
    required this.courseId,
    required this.categoryId,
  });

  @override
  State<CategoryActivitiesScreen> createState() =>
      _CategoryActivitiesScreenState();
}

class _CategoryActivitiesScreenState extends State<CategoryActivitiesScreen> {
  late final ActivitiesController controller;

  @override
  void initState() {
    super.initState();
    controller = ActivitiesController();
    controller.addListener(_onChange);
    controller.loadByCategory(widget.categoryId);
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _createActivityDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? dueDate;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Actividad'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dueDate == null
                            ? 'Sin fecha límite'
                            : 'Fecha: ${dueDate!.toLocal()}',
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: now,
                          lastDate: DateTime(now.year + 2),
                          initialDate: now,
                        );
                        if (picked != null) {
                          setState(() => dueDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await controller.createActivity(
                courseId: widget.courseId,
                categoryId: widget.categoryId,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                dueDate: dueDate,
              );
              await controller.loadByCategory(widget.categoryId);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchAssessment(String activityId) async {
    await controller.launchAssessment(activityId);
    await controller.loadAssessment(activityId);
  }

  Future<void> _closeAssessment(String activityId) async {
    await controller.closeAssessment(activityId);
    await controller.loadAssessment(activityId);
  }

  Widget _assessmentBadge(String activityId) {
    final Assessment? a = controller.assessmentFor(activityId);
    if (a == null) {
      return TextButton.icon(
        onPressed: controller.loading
            ? null
            : () => _launchAssessment(activityId),
        icon: const Icon(Icons.play_circle_fill),
        label: const Text('Lanzar'),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          a.closed ? Icons.check_circle : Icons.circle_outlined,
          color: a.closed ? Colors.green : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          a.closed ? 'Cerrada' : 'Activa',
          style: TextStyle(color: a.closed ? Colors.green : Colors.orange),
        ),
        if (!a.closed)
          TextButton(
            onPressed: controller.loading
                ? null
                : () => _closeAssessment(activityId),
            child: const Text('Cerrar'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades de la Categoría')),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => controller.loadByCategory(widget.categoryId),
              child: ListView.builder(
                itemCount: controller.categoryActivities.length,
                itemBuilder: (context, index) {
                  final Activity a = controller.categoryActivities[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(a.title),
                      subtitle: Text(a.description),
                      trailing: _assessmentBadge(a.id),
                      onTap: () async {
                        await controller.loadAssessment(a.id);
                        if (mounted) setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.loading ? null : _createActivityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
