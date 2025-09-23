import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/category.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import '../controllers/activities_controller.dart';
import 'activity_detail_screen.dart';

/// Lista todas las actividades del curso sin agrupar, con FAB para crear.
class CourseActivitiesScreen extends StatefulWidget {
  final String courseId;
  const CourseActivitiesScreen({super.key, required this.courseId});

  @override
  State<CourseActivitiesScreen> createState() => _CourseActivitiesScreenState();
}

class _CourseActivitiesScreenState extends State<CourseActivitiesScreen> {
  late final ActivitiesController controller;

  String _fmtDateTime(DateTime dt) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  void initState() {
    super.initState();
    controller = ActivitiesController();
    controller.addListener(_onChange);
    controller.loadByCourse(widget.courseId);
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _createActivityDialog() async {
    final repo = Provider.of<LocalRepository>(context, listen: false);
    final categories = repo.categoriesBox.values
        .where((c) => c.courseId == widget.courseId)
        .toList();
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una categoría.')),
      );
      return;
    }
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate; // incluye fecha y hora
    Category? selectedCategory = categories.first;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Nueva Actividad'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Category>(
                      value: selectedCategory,
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(value: c, child: Text(c.name)),
                      ],
                      onChanged: (v) =>
                          setStateDialog(() => selectedCategory = v),
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
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
                                : 'Fecha: ${_fmtDateTime(dueDate!)}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Elegir fecha',
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: now,
                              lastDate: DateTime(now.year + 2),
                              initialDate: dueDate ?? now,
                            );
                            if (picked != null) {
                              final existing = dueDate;
                              final hour = existing?.hour ?? 0;
                              final minute = existing?.minute ?? 0;
                              setStateDialog(() {
                                dueDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  hour,
                                  minute,
                                );
                              });
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Elegir hora',
                          icon: const Icon(Icons.schedule),
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                dueDate ?? DateTime.now(),
                              ),
                            );
                            if (pickedTime != null) {
                              final base = dueDate ?? DateTime.now();
                              setStateDialog(() {
                                dueDate = DateTime(
                                  base.year,
                                  base.month,
                                  base.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          },
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
                    categoryId: selectedCategory!.id,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    dueDate: dueDate,
                  );
                  await controller.loadByCourse(widget.courseId);
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Crear'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final course = repo.coursesBox.get(widget.courseId);
    final isCreator =
        user != null && course != null && user.id == course.teacherId;

    return Scaffold(
      appBar: const TopBar(title: 'Actividades del Curso'),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.courseActivities.isEmpty
          ? const Center(child: Text('No hay actividades todavía.'))
          : ListView.builder(
              itemCount: controller.courseActivities.length,
              itemBuilder: (context, index) {
                final a = controller.courseActivities[index];
                final cat = repo.categoriesBox.get(a.categoryId);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(a.title),
                    subtitle: Text(
                      cat == null ? 'Categoría eliminada' : cat.name,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailScreen(
                            activityId: a.id,
                            courseId: widget.courseId,
                          ),
                        ),
                      );
                      if (changed == true) {
                        controller.loadByCourse(widget.courseId);
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: isCreator
          ? FloatingActionButton(
              onPressed: _createActivityDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
