import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/category.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';

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
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final course = repo.coursesBox.get(widget.courseId);
    final isCreator = user != null && course != null && user.id == course.teacherId;
    final categories = repo.categoriesBox.values.where((c) => c.courseId == widget.courseId).toList();

    return Scaffold(
    appBar: const TopBar(title: 'Categorías'),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final c = categories[index];
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
                      final cat = repo.categoriesBox.get(c.id);
                      if (cat == null) return;
                      final nameController = TextEditingController(text: cat.name);
                      bool randomAssign = cat.randomAssign;
                      int studentsPerGroup = cat.studentsPerGroup;
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
                                      await repo.updateCategory(c.id, name: name, randomAssign: randomAssign, studentsPerGroup: studentsPerGroup);
                                      if (mounted) setState(() {});
                                      Navigator.pop(context);
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
                  IconButton(icon: const Icon(Icons.delete), onPressed: () async { await repo.deleteCategory(c.id); setState(() {}); }),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: (widget.canCreate && isCreator)
          ? FloatingActionButton(
              onPressed: () async {
                final nameController = TextEditingController();
                bool randomAssign = false;
                int studentsPerGroup = 2;
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
                                final id = DateTime.now().millisecondsSinceEpoch.toString();
                                final cat = Category(
                                  id: id,
                                  courseId: widget.courseId,
                                  name: name,
                                  randomAssign: randomAssign,
                                  studentsPerGroup: studentsPerGroup,
                                );
                                await repo.createCategory(cat);
                                if (randomAssign) {
                                  await repo.createGroupsForCategory(cat.id);
                                }
                                if (mounted) setState(() {});
                                Navigator.pop(context);
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
