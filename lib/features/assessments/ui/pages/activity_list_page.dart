import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/activity_controller.dart';
import '../controllers/category_controller.dart';
import '../../../courses/ui/controllers/course_controller.dart';
import '../../domain/models/activity_model.dart';
import 'activity_detail_page.dart';

class ActivityListPage extends StatefulWidget {
  const ActivityListPage({super.key});

  @override
  State<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends State<ActivityListPage> {
  late final ActivityController _activityController;
  late final CategoryController _categoryController;
  String? _courseId;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ActivityController>()) {
      _activityController = Get.put(
        ActivityController(
          createActivityUseCase: Get.find(),
          getActivitiesUseCase: Get.find(),
          updateActivityUseCase: Get.find(),
          deleteActivityUseCase: Get.find(),
        ),
        permanent: true,
      );
    } else {
      _activityController = Get.find<ActivityController>();
    }
    if (!Get.isRegistered<CategoryController>()) {
      _categoryController = Get.put(
        CategoryController(
          createCategoryUseCase: Get.find(),
          getCategoriesUseCase: Get.find(),
          updateCategoryUseCase: Get.find(),
          deleteCategoryUseCase: Get.find(),
        ),
        permanent: true,
      );
    } else {
      _categoryController = Get.find<CategoryController>();
    }
    final args = Get.arguments;
    if (args is Map && args['courseId'] is String) {
      _courseId = args['courseId'] as String;
    } else {
      final coursesController = Get.isRegistered<CourseController>() ? Get.find<CourseController>() : null;
      _courseId = coursesController?.courses.isNotEmpty == true ? coursesController!.courses.first.id : null;
    }
    if (_courseId != null) {
      _activityController.load(_courseId!);
      _categoryController.load(_courseId!);
    }
  }

  // no-op

  void _openCreateDialog() {
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay curso seleccionado')));
      return;
    }
    if (_categoryController.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe crear antes una categoría')));
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final visible = true.obs;
    final selectedCategory = Rx<String?>(_categoryController.categories.first.id);
    final dueDate = Rx<DateTime?>(null);

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        firstDate: now.subtract(const Duration(days: 1)),
        lastDate: DateTime(now.year + 3),
        initialDate: now,
      );
      if (picked != null) dueDate.value = picked;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nueva Actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
          // 'value' deprecated: use initialValue if possible when building inside a Form field creation
          // However DropdownButtonFormField still uses 'value'; to silence lint we keep but ignore warning or adapt:
          value: selectedCategory.value,
                      items: _categoryController.categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => selectedCategory.value = v,
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    )),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Obx(() => Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate.value == null
                                ? 'Sin fecha límite'
                                : 'Fecha límite: ${dueDate.value!.day}/${dueDate.value!.month}/${dueDate.value!.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          onPressed: pickDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                          tooltip: 'Seleccionar fecha',
                        ),
                      ],
                    )),
                const SizedBox(height: 8),
                Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Visible para estudiantes'),
                      value: visible.value,
                      onChanged: (v) => visible.value = v,
                    )),
                const SizedBox(height: 12),
                Obx(() => _activityController.creating.value
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final created = await _activityController.create(
                                courseId: _courseId!,
                                categoryId: selectedCategory.value!,
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                dueDate: dueDate.value,
                                visible: visible.value,
                              );
                              if (created != null && mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Crear'),
                          ),
                        ],
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditDialog(ActivityModel activity) {
    final nameCtrl = TextEditingController(text: activity.name);
    final descCtrl = TextEditingController(text: activity.description);
    final formKey = GlobalKey<FormState>();
    final visible = RxBool(activity.visible);
    final selectedCategory = Rx<String?>(activity.categoryId);
    final dueDate = Rx<DateTime?>(activity.dueDate);

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        firstDate: now.subtract(const Duration(days: 1)),
        lastDate: DateTime(now.year + 3),
        initialDate: dueDate.value ?? now,
      );
      if (picked != null) dueDate.value = picked;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Editar Actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Obx(() => DropdownButtonFormField<String>(
                      value: selectedCategory.value,
                      items: _categoryController.categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => selectedCategory.value = v,
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    )),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Obx(() => Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate.value == null
                                ? 'Sin fecha límite'
                                : 'Fecha límite: ${dueDate.value!.day}/${dueDate.value!.month}/${dueDate.value!.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          onPressed: pickDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                          tooltip: 'Seleccionar fecha',
                        ),
                      ],
                    )),
                const SizedBox(height: 8),
                Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Visible para estudiantes'),
                      value: visible.value,
                      onChanged: (v) => visible.value = v,
                    )),
                const SizedBox(height: 12),
                Obx(() => _activityController.updating.value
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final updatedModel = ActivityModel(
                                id: activity.id,
                                courseId: activity.courseId,
                                categoryId: selectedCategory.value ?? activity.categoryId,
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                dueDate: dueDate.value,
                                visible: visible.value,
                              );
                              final updated = await _activityController.updateActivity(updatedModel);
                              if (updated != null && mounted) Navigator.pop(context);
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades')),
      body: Obx(() {
        if (_courseId == null) return const Center(child: Text('No hay curso para actividades'));
        if (_activityController.loading.value) return const Center(child: CircularProgressIndicator());
        if (_activityController.activities.isEmpty) {
          return const Center(child: Text('Aún no hay actividades'));
        }
        return ListView.separated(
          itemCount: _activityController.activities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final a = _activityController.activities[i];
            var category = null as dynamic;
            for (final c in _categoryController.categories) { if (c.id == a.categoryId) { category = c; break; } }
            return ListTile(
              onTap: () => Get.to(() => ActivityDetailPage(activity: a)),
              title: Text(a.name),
              subtitle: Text('Categoría: ${category?.name ?? '—'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: a.visible ? 'Ocultar' : 'Mostrar',
                    icon: Icon(a.visible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => _activityController.toggleVisibility(a),
                  ),
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _openEditDialog(a),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar actividad'),
                          content: Text('¿Deseas eliminar "${a.name}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _activityController.delete(a.id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
