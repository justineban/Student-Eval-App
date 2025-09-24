import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/models/activity_model.dart';
import '../controllers/activity_controller.dart';
import '../controllers/category_controller.dart';
import 'activity_evaluation_page.dart';

class ActivityDetailPage extends StatefulWidget {
  final ActivityModel activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late final ActivityController _activityController;
  late final CategoryController _categoryController;

  @override
  void initState() {
    super.initState();
    _activityController = Get.find<ActivityController>();
    _categoryController = Get.find<CategoryController>();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
  dynamic category;
    for (final c in _categoryController.categories) {
      if (c.id == a.categoryId) { category = c; break; }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de actividad')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Categoría: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(category?.name ?? '—'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Fecha límite: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(a.dueDate == null
                    ? 'Sin fecha'
                    : '${a.dueDate!.day}/${a.dueDate!.month}/${a.dueDate!.year}'),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible para estudiantes'),
              value: a.visible,
              onChanged: (v) async {
                await _activityController.toggleVisibility(a);
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 16),
            const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              a.description,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => ActivityEvaluationPage(activity: a)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar evaluación'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// no-op
