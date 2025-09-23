import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../assessments/ui/controllers/category_controller.dart';
import '../../ui/controllers/course_controller.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});
  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late final CategoryController _categoryController;
  String? _courseId; // Se podría pasar por args en el futuro

  @override
  void initState() {
    super.initState();
    _categoryController = Get.find<CategoryController>();
    // Por ahora se usa el primer curso del profesor si existe
    final coursesController = Get.isRegistered<CourseController>() ? Get.find<CourseController>() : null;
    _courseId = coursesController?.courses.isNotEmpty == true ? coursesController!.courses.first.id : null;
    if (_courseId != null) {
      _categoryController.load(_courseId!);
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
