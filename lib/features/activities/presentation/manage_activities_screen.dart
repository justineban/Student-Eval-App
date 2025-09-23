import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/entities/category.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/category/presentation/categories_list_screen.dart'
    as teacher_categories;
import '../controllers/activities_controller.dart';
import '../domain/activity_entity.dart';
import '../domain/assessment_entity.dart';

/// Pantalla integral para gestionar actividades por categoría.
/// - Lista categorías con ExpansionTile
/// - Dentro de cada categoría se listan actividades y se permite crear nuevas
/// - Control de assessment (lanzar / cerrar) por actividad
class ManageActivitiesScreen extends StatefulWidget {
  final String courseId;
  const ManageActivitiesScreen({super.key, required this.courseId});

  @override
  State<ManageActivitiesScreen> createState() => _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState extends State<ManageActivitiesScreen> {
  late final ActivitiesController controller;
  final Map<String, List<Activity>> _activitiesByCategory = {};
  final Map<String, bool> _loadingCategory = {};

  @override
  void initState() {
    super.initState();
    controller = ActivitiesController();
    controller.addListener(_onChange);
    _preload();
  }

  void _preload() async {
    final repo = Provider.of<LocalRepository>(context, listen: false);
    final categories = repo.categoriesBox.values
        .where((c) => c.courseId == widget.courseId)
        .toList();
    for (final cat in categories) {
      _loadingCategory[cat.id] = true;
      final list = await controller.fetchActivitiesForCategory(cat.id);
      _activitiesByCategory[cat.id] = list;
      _loadingCategory[cat.id] = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }

  void _onChange() {
    setState(() {});
  }

  Future<void> _createActivity(Category cat) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueDate;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nueva Actividad - ${cat.name}'),
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
                            : 'Fecha: ${dueDate!.toLocal().toString().split(' ').first}',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: now,
                          lastDate: DateTime(now.year + 2),
                          initialDate: now,
                        );
                        if (picked != null) setState(() => dueDate = picked);
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
                categoryId: cat.id,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                dueDate: dueDate,
              );
              final list = await controller.fetchActivitiesForCategory(cat.id);
              _activitiesByCategory[cat.id] = list;
              if (mounted) setState(() {});
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAssessment(Activity a) async {
    final current = controller.assessmentFor(a.id);
    if (current == null) {
      await controller.launchAssessment(a.id);
    } else if (!current.closed) {
      await controller.closeAssessment(a.id);
    }
    await controller.loadAssessment(a.id);
    if (mounted) setState(() {});
  }

  Widget _assessmentChip(Activity a) {
    final Assessment? assess = controller.assessmentFor(a.id);
    if (assess == null) {
      return ActionChip(
        label: const Text('Lanzar'),
        avatar: const Icon(Icons.play_arrow, size: 18),
        onPressed: controller.loading ? null : () => _toggleAssessment(a),
      );
    }
    if (!assess.closed) {
      return ActionChip(
        label: const Text('Cerrar'),
        avatar: const Icon(Icons.stop_circle, size: 18),
        onPressed: controller.loading ? null : () => _toggleAssessment(a),
      );
    }
    return const Chip(
      label: Text('Cerrada'),
      avatar: Icon(Icons.check_circle, color: Colors.green, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final course = repo.coursesBox.get(widget.courseId);
    final isCreator =
        user != null && course != null && user.id == course.teacherId;
    final categories = repo.categoriesBox.values
        .where((c) => c.courseId == widget.courseId)
        .toList();

    return Scaffold(
      appBar: const TopBar(title: 'Gestionar Actividades'),
      body: categories.isEmpty
          ? const Center(
              child: Text('No hay categorías. Crea primero una categoría.'),
            )
          : ListView(
              children: [
                if (!isCreator)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Vista de solo lectura (no eres el docente).',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ...categories.map((cat) {
                  final loading = _loadingCategory[cat.id] == true;
                  final acts = _activitiesByCategory[cat.id] ?? [];
                  return ExpansionTile(
                    key: PageStorageKey(cat.id),
                    title: Text(cat.name),
                    subtitle: Text('${acts.length} actividad(es)'),
                    trailing: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    children: [
                      if (acts.isEmpty && !loading)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Sin actividades aún.'),
                        ),
                      ...acts.map(
                        (a) => ListTile(
                          title: Text(a.title),
                          subtitle: Text(a.description),
                          trailing: _assessmentChip(a),
                        ),
                      ),
                      if (isCreator)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _createActivity(cat),
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir actividad'),
                          ),
                        ),
                      const Divider(height: 1),
                    ],
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: isCreator
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => teacher_categories.CategoriesListScreen(
                    courseId: widget.courseId,
                    canCreate: true,
                  ),
                ),
              ),
              icon: const Icon(Icons.category),
              label: const Text('Categorías'),
            )
          : null,
    );
  }
}
