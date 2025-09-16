import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/teacher_view/data/category_service.dart';

class CreateCategoryPage extends StatefulWidget {
  final String courseId;
  const CreateCategoryPage({super.key, required this.courseId});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage> {
  final _nameController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  String _selectedGroupingMethod = 'random';

  @override
  void dispose() {
    _nameController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  void _createCategory() async {
    if (_nameController.text.isEmpty || _maxStudentsController.text.isEmpty) return;
    final categoryService = CategoryService();
    await categoryService.addCategory(
      widget.courseId,
      _nameController.text.trim(),
      _selectedGroupingMethod == 'random',
      int.parse(_maxStudentsController.text.trim()),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Categoría')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedGroupingMethod,
              items: const [
                DropdownMenuItem(value: 'random', child: Text('Aleatorio')),
                DropdownMenuItem(value: 'self', child: Text('Auto-asignado')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGroupingMethod = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxStudentsController,
              decoration: const InputDecoration(labelText: 'Máximo de estudiantes por grupo'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _createCategory, child: const Text('Crear Categoría')),
          ],
        ),
      ),
    );
  }
}
