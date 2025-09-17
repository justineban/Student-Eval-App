import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';

class EditCategoryScreen extends StatelessWidget {
  final String categoryId;
  const EditCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final cat = repo.categoriesBox.get(categoryId);
    if (cat == null) {
      return const Scaffold(body: Center(child: Text('Categoría no encontrada')));
    }
    final nameController = TextEditingController(text: cat.name);
    bool randomAssign = cat.randomAssign;
    int studentsPerGroup = cat.studentsPerGroup;

    Future<void> showEditDialog() async {
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
                      await repo.updateCategory(categoryId, name: name, randomAssign: randomAssign, studentsPerGroup: studentsPerGroup);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    // Mostrar el diálogo automáticamente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showEditDialog();
    });

    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
