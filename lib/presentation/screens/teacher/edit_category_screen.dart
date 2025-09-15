import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';

class EditCategoryScreen extends StatefulWidget {
  final String categoryId;
  const EditCategoryScreen({super.key, required this.categoryId});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _name = TextEditingController();
  bool _random = true;
  final _size = TextEditingController();

  @override
  void initState() {
    super.initState();
    final repo = LocalRepository.instance;
    final cat = repo.categoriesBox.get(widget.categoryId);
    if (cat != null) {
      _name.text = cat.name;
      _random = cat.randomAssign;
      _size.text = cat.studentsPerGroup.toString();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Categoría')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre')),
            SwitchListTile(title: const Text('Asignación aleatoria'), value: _random, onChanged: (v) => setState(() => _random = v)),
            TextField(controller: _size, decoration: const InputDecoration(labelText: 'Estudiantes por grupo'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async { final navigator = Navigator.of(context); await repo.updateCategory(widget.categoryId, name: _name.text.trim(), randomAssign: _random, studentsPerGroup: int.tryParse(_size.text) ?? 2); if (!mounted) return; navigator.pop(); }, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
