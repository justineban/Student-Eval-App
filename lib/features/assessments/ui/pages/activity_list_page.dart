import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/list_button_card.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import '../controllers/activity_controller.dart';
import '../controllers/category_controller.dart';
import '../../../courses/ui/controllers/course_controller.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../courses/domain/repositories/course_repository.dart';
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
  late final AuthController _auth;
  bool _isTeacher = false;

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
      final coursesController = Get.isRegistered<CourseController>()
          ? Get.find<CourseController>()
          : null;
      _courseId = coursesController?.courses.isNotEmpty == true
          ? coursesController!.courses.first.id
          : null;
    }
    _auth = Get.find<AuthController>();
    if (_courseId != null) {
      _activityController.load(_courseId!);
      _categoryController.load(_courseId!);
      _determineRole();
    }
  }

  // no-op

  Future<void> _determineRole() async {
    try {
      final repo = Get.find<CourseRepository>();
      final course = await repo.getCourseById(_courseId!);
      final uid = _auth.currentUser.value?.id;
      if (mounted) setState(() => _isTeacher = (course?.teacherId == uid));
    } catch (_) {
      if (mounted) setState(() => _isTeacher = false);
    }
  }

  String _dueWarning(ActivityModel a) {
    final due = a.dueDate;
    if (due == null) return 'Sin fecha límite';
    final now = DateTime.now();
    if (due.isAfter(now)) {
      final diff = due.difference(now);
      if (diff.inDays >= 1)
        return 'Quedan ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
      if (diff.inHours >= 1)
        return 'Quedan ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
      final mins = diff.inMinutes.clamp(0, 1000000);
      return 'Quedan $mins min';
    } else {
      final diff = now.difference(due);
      if (diff.inDays >= 1)
        return 'Vencida hace ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
      if (diff.inHours >= 1)
        return 'Vencida hace ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
      final mins = diff.inMinutes.clamp(0, 1000000);
      return 'Vencida hace $mins min';
    }
  }

  void _openCreateDialog() {
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay curso seleccionado')),
      );
      return;
    }
    if (_categoryController.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe crear antes una categoría')),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final visible = true.obs;
    final selectedCategory = Rx<String?>(
      _categoryController.categories.first.id,
    );
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
                const Text(
                  'Nueva Actividad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: selectedCategory.value,
                    items: _categoryController.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedCategory.value = v,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
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
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible para estudiantes'),
                    value: visible.value,
                    onChanged: (v) => visible.value = v,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _activityController.creating.value
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                final created = await _activityController
                                    .create(
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
                        ),
                ),
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
                const Text(
                  'Editar Actividad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: selectedCategory.value,
                    items: _categoryController.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedCategory.value = v,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
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
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible para estudiantes'),
                    value: visible.value,
                    onChanged: (v) => visible.value = v,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _activityController.updating.value
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                final updatedModel = ActivityModel(
                                  id: activity.id,
                                  courseId: activity.courseId,
                                  categoryId:
                                      selectedCategory.value ??
                                      activity.categoryId,
                                  name: nameCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  dueDate: dueDate.value,
                                  visible: visible.value,
                                );
                                final updated = await _activityController
                                    .updateActivity(updatedModel);
                                if (updated != null && mounted)
                                  Navigator.pop(context);
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                ),
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
      appBar: const AppTopBar(title: 'Actividades'),
      body: Obx(() {
        if (_courseId == null)
          return const Center(child: Text('No hay curso para actividades'));
        if (_activityController.loading.value)
          return const Center(child: CircularProgressIndicator());
        // Filter for students: only visible activities
        final items = _isTeacher
            ? _activityController.activities
            : _activityController.activities
                  .where((a) => a.visible)
                  .toList(growable: false);
        if (items.isEmpty) {
          return const Center(child: Text('Aún no hay actividades'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final a = items[i];
            var category = null as dynamic;
            for (final c in _categoryController.categories) {
              if (c.id == a.categoryId) {
                category = c;
                break;
              }
            }
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final containerColor = scheme.secondaryContainer.withValues(
              alpha: 0.75,
            );
            final subtitle = _isTeacher
                ? 'Categoría: ${category?.name ?? '—'}'
                : 'Categoría: ${category?.name ?? '—'}\n${_dueWarning(a)}';

            if (_isTeacher) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListButtonCard(
                      leadingIcon: Icons.assignment_outlined,
                      title: a.name,
                      subtitle: subtitle,
                      trailingChip: a.visible ? 'Visible' : 'Oculta',
                      containerColor: containerColor,
                      onTap: () =>
                          Get.to(() => ActivityDetailPage(activity: a)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: a.visible ? 'Ocultar' : 'Mostrar',
                        icon: Icon(
                          a.visible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            _activityController.toggleVisibility(a),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openEditDialog(a),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar actividad'),
                              content: Text('¿Deseas eliminar "${a.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
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
                ],
              );
            } else {
              return ListButtonCard(
                leadingIcon: Icons.assignment_outlined,
                title: a.name,
                subtitle: subtitle,
                containerColor: containerColor,
                onTap: () => Get.to(() => ActivityDetailPage(activity: a)),
              );
            }
          },
        );
      }),
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              onPressed: _openCreateDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
