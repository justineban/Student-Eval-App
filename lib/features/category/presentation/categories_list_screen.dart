import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/controllers/categories_controller.dart';

class CategoriesListScreen extends StatefulWidget {
  final String courseId;
  final bool canCreate;
  const CategoriesListScreen({super.key, required this.courseId, this.canCreate = true});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  @override
  Widget build(BuildContext context) {
  final categoriesController = Get.find<CategoriesController>();
  // Ensures data loaded (idempotent)
  categoriesController.load(widget.courseId);
  // Derive isCreator by checking any loaded course list (fallback to passed canCreate flag)
  final isCreator = widget.canCreate; // refined logic can be added later

    return Scaffold(
    appBar: const TopBar(title: 'Categorías'),
      body: Obx(() {
        final list = categoriesController.categories;
        if (categoriesController.isLoading.value && list.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (list.isEmpty) {
          return const Center(child: Text('Sin categorías'));
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final c = list[index];
            return ListTile(
              title: Text(c.name),
              subtitle: Text('${c.randomAssign ? 'Aleatorio' : 'Libre'} - ${c.studentsPerGroup} por grupo'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/groups', arguments: c.id),
                    child: const Text('Ver grupos'),
                  ),
                  if (isCreator) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final nameController = TextEditingController(text: c.name);
                        bool randomAssign = c.randomAssign;
                        int studentsPerGroup = c.studentsPerGroup;
                        final navigator = Navigator.of(context);
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text('Editar categoría'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameController,
                                        decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
                                      ),
                                      Row(
                                        children: [
                                          const Text('Tipo de asignación: '),
                                          Expanded(
                                            child: SegmentedButton<bool>(
                                              segments: const [
                                                ButtonSegment(value: false, label: Text('Libre')),
                                                ButtonSegment(value: true, label: Text('Aleatorio')),
                                              ],
                                              selected: <bool>{randomAssign},
                                              onSelectionChanged: (v) => setState(() => randomAssign = v.first),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Máx. estudiantes por grupo'),
                                        controller: TextEditingController(text: studentsPerGroup.toString()),
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val);
                                          if (parsed != null) studentsPerGroup = parsed;
                                        },
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final name = nameController.text.trim();
                                        if (name.isEmpty) return;
                                        await categoriesController.updateOne(c.id, name: name, randomAssign: randomAssign, studentsPerGroup: studentsPerGroup);
                                        navigator.pop();
                                      },
                                      child: const Text('Guardar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await categoriesController.deleteOne(c.id);
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: (widget.canCreate && isCreator)
          ? FloatingActionButton(
              onPressed: () async {
                final nameController = TextEditingController();
                bool randomAssign = false;
                int studentsPerGroup = 2;
                final navigator = Navigator.of(context);
                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Crear categoría'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
                              ),
                              Row(
                                children: [
                                  const Text('Tipo de asignación: '),
                                  Expanded(
                                    child: SegmentedButton<bool>(
                                      segments: const [
                                        ButtonSegment(value: false, label: Text('Libre')),
                                        ButtonSegment(value: true, label: Text('Aleatorio')),
                                      ],
                                      selected: <bool>{randomAssign},
                                      onSelectionChanged: (v) => setState(() => randomAssign = v.first),
                                    ),
                                  ),
                                ],
                              ),
                              TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Máx. estudiantes por grupo'),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null) studentsPerGroup = parsed;
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) return;
                                final created = await categoriesController.createNew(
                                  name: name,
                                  randomAssign: randomAssign,
                                  studentsPerGroup: studentsPerGroup,
                                );
                                if (created != null && randomAssign) {
                                  // TODO: disparar generación de grupos automática cuando exista el use case
                                }
                                navigator.pop();
                              },
                              child: const Text('Crear categoría'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              tooltip: 'Crear categoría',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
