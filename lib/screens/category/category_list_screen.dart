import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';

class CategoryListScreen extends StatefulWidget {
  final String courseId;

  const CategoryListScreen({super.key, required this.courseId});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final _categoryService = CategoryService();
  final _nameController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  String _selectedGroupingMethod = 'random';

  @override
  Widget build(BuildContext context) {
    final categories = _categoryService.getCategoriesForCourse(widget.courseId);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            title: Text(category.name),
            subtitle: Text('Método: ${category.groupingMethod}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditCategoryDialog(category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCategory(category),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedGroupingMethod,
              items: const [
                DropdownMenuItem(value: 'random', child: Text('Aleatorio')),
                DropdownMenuItem(value: 'self', child: Text('Auto-asignado')),
              ],
              onChanged: (value) {
                setState(() => _selectedGroupingMethod = value!);
              },
            ),
            TextField(
              controller: _maxStudentsController,
              decoration: const InputDecoration(
                labelText: 'Máximo de estudiantes por grupo',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _addCategory();
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _addCategory() async {
    if (_nameController.text.isEmpty || _maxStudentsController.text.isEmpty) {
      return;
    }

    await _categoryService.addCategory(
      widget.courseId,
      _nameController.text,
      _selectedGroupingMethod,
      int.parse(_maxStudentsController.text),
    );

    setState(() {
      _nameController.clear();
      _maxStudentsController.clear();
    });
  }

  void _showEditCategoryDialog(Category category) {
    _nameController.text = category.name;
    _selectedGroupingMethod = category.groupingMethod;
    _maxStudentsController.text = category.maxStudentsPerGroup.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedGroupingMethod,
              items: const [
                DropdownMenuItem(value: 'random', child: Text('Aleatorio')),
                DropdownMenuItem(value: 'self', child: Text('Auto-asignado')),
              ],
              onChanged: (value) {
                setState(() => _selectedGroupingMethod = value!);
              },
            ),
            TextField(
              controller: _maxStudentsController,
              decoration: const InputDecoration(
                labelText: 'Máximo de estudiantes por grupo',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _updateCategory(category);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _updateCategory(Category category) {
    if (_nameController.text.isEmpty || _maxStudentsController.text.isEmpty) {
      return;
    }

    final updatedCategory = Category(
      id: category.id,
      courseId: widget.courseId,
      name: _nameController.text,
      groupingMethod: _selectedGroupingMethod,
      maxStudentsPerGroup: int.parse(_maxStudentsController.text),
      studentGroups: category.studentGroups,
    );

    _categoryService.updateCategory(widget.courseId, updatedCategory);

    setState(() {
      _nameController.clear();
      _maxStudentsController.clear();
    });
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _categoryService.deleteCategory(widget.courseId, category.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
