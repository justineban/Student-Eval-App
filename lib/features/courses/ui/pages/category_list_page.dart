import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../assessments/ui/controllers/category_controller.dart';
import '../../../assessments/domain/models/category_model.dart';
import '../../ui/controllers/course_controller.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../domain/repositories/course_repository.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});
  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late final CategoryController _categoryController;
  String? _courseId; // Se podría pasar por args en el futuro
  late final AuthController _auth;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _categoryController = Get.find<CategoryController>();
    _auth = Get.find<AuthController>();
    // Intentar obtener courseId desde argumentos primero
    final args = Get.arguments;
    if (args is Map && args['courseId'] is String) {
      _courseId = args['courseId'] as String;
    } else {
      final coursesController = Get.isRegistered<CourseController>() ? Get.find<CourseController>() : null;
      _courseId = coursesController?.courses.isNotEmpty == true ? coursesController!.courses.first.id : null;
    }
    if (_courseId != null) {
      _categoryController.load(_courseId!);
      _determineRole();
    }
  }

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

  void _openCreateDialog() {
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay curso seleccionado')));
      return;
    }
    final nameCtrl = TextEditingController();
    final maxCtrl = TextEditingController(text: '5');
    final formKey = GlobalKey<FormState>();
    final random = false.obs;
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
                const Text('Nueva Categoría', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxCtrl,
                  decoration: const InputDecoration(labelText: 'Máx. estudiantes / grupo', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = int.tryParse(v ?? '');
                    if (value == null || value <= 0) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Grupos aleatorios'),
                      value: random.value,
                      onChanged: (val) => random.value = val,
                    )),
                const SizedBox(height: 12),
                Obx(() => _categoryController.creating.value
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final maxVal = int.parse(maxCtrl.text.trim());
                              final created = await _categoryController.create(
                                courseId: _courseId!,
                                name: nameCtrl.text.trim(),
                                randomGroups: random.value,
                                maxStudentsPerGroup: maxVal,
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

  void _openEditDialog(CategoryModel category) {
    final nameCtrl = TextEditingController(text: category.name);
    final maxCtrl = TextEditingController(text: category.maxStudentsPerGroup.toString());
    final formKey = GlobalKey<FormState>();
    final random = RxBool(category.randomGroups);
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
                const Text('Editar Categoría', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxCtrl,
                  decoration: const InputDecoration(labelText: 'Máx. estudiantes / grupo', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = int.tryParse(v ?? '');
                    if (value == null || value <= 0) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Grupos aleatorios'),
                      value: random.value,
                      onChanged: (val) => random.value = val,
                    )),
                const SizedBox(height: 12),
                Obx(() => _categoryController.updating.value
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final maxVal = int.parse(maxCtrl.text.trim());
                              final updated = await _categoryController.updateCategory(
                                category,
                                name: nameCtrl.text.trim(),
                                randomGroups: random.value,
                                maxStudentsPerGroup: maxVal,
                              );
                              if (updated != null && mounted) {
                                Navigator.pop(context);
                              }
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

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Seguro que desea eliminar "${category.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          Obx(() => _categoryController.deleting.value
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: () async {
                    final ok = await _categoryController.delete(category.id);
                    if (ok && mounted) Navigator.pop(context);
                  },
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: Obx(() {
        if (_courseId == null) {
          return const Center(child: Text('No hay curso para mostrar categorías'));
        }
        if (_categoryController.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_categoryController.categories.isEmpty) {
          return const Center(child: Text('Aún no hay categorías'));
        }
        return ListView.separated(
          itemCount: _categoryController.categories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = _categoryController.categories[i];
            return ListTile(
              title: Text(c.name),
              subtitle: Text('Máx: ${c.maxStudentsPerGroup}  •  ${c.randomGroups ? 'Aleatorio' : 'Manual'}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  Tooltip(
                    message: 'Ver grupos',
                    child: IconButton(
                      icon: const Icon(Icons.group_outlined),
                      onPressed: () => _categoryController.viewGroups(c),
                    ),
                  ),
                  if (_isTeacher)
                    Tooltip(
                    message: 'Editar',
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openEditDialog(c),
                    ),
                  ),
                  if (_isTeacher)
                    Tooltip(
                    message: 'Eliminar',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(c),
                    ),
                  ),
                ],
              ),
            );
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
