import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/category.dart';
import 'package:uuid/uuid.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';

class CreateCategoryScreen extends StatefulWidget {
  final String courseId;
  const CreateCategoryScreen({super.key, required this.courseId});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  bool _random = true;
  final _size = TextEditingController(text: '2');
  final _name = TextEditingController();

  @override
  void dispose() {
    _size.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    return Scaffold(
    appBar: const TopBar(title: 'Crear Categoría'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre de la categoría')),
            Row(
              children: [
                const Text('Tipo de asignación: '),
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Libre')),
                      ButtonSegment(value: true, label: Text('Aleatorio')),
                    ],
                    selected: <bool>{_random},
                    onSelectionChanged: (v) => setState(() => _random = v.first),
                  ),
                ),
              ],
            ),
            TextField(controller: _size, decoration: const InputDecoration(labelText: 'Estudiantes por grupo'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final id = const Uuid().v4();
                final cat = Category(id: id, courseId: widget.courseId, name: _name.text.trim().isEmpty ? 'Categoria' : _name.text.trim(), randomAssign: _random, studentsPerGroup: int.tryParse(_size.text) ?? 2);
                await repo.createCategory(cat);
                if (_random) {
                  await repo.createGroupsForCategory(cat.id);
                }
                if (!mounted) return;
                navigator.pop();
              },
              child: const Text('Crear categoría'),
            )
          ],
        ),
      ),
    );
  }
}
