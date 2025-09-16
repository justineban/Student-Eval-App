import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/teacher_view/domain/entities/category.dart';
import 'package:proyecto_movil/features/teacher_view/data/category_service.dart';
import 'package:proyecto_movil/features/teacher_view/presentation/pages/teacher_group_list_page.dart';

class CategoryListPage extends StatefulWidget {
	final String courseId;
	const CategoryListPage({super.key, required this.courseId});

	@override
	State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
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
				onPressed: () {
					_showAddCategoryDialog();
				},
				child: const Icon(Icons.add),
			),
			body: ListView.builder(
				itemCount: categories.length,
				itemBuilder: (context, index) {
					final category = categories[index];
					return ListTile(
						title: Text(category.name),
						subtitle: Text('Método: ${category.randomAssign ? 'Aleatorio' : 'Auto-asignado'}'),
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
								// Botón para ver grupos en la categoría
								IconButton(
									icon: const Icon(Icons.group),
									onPressed: () {
									Navigator.push(context, MaterialPageRoute(builder: (_) =>
										TeacherGroupListPage(categoryId: category.id)));
								},
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
							initialValue: _selectedGroupingMethod,
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
							decoration: const InputDecoration(labelText: 'Máximo de estudiantes por grupo'),
							keyboardType: TextInputType.number,
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context), 
						child: const Text('Cancelar')
					),
					TextButton(
						// Updated to avoid using BuildContext across async gap
						onPressed: () async {
							if (_nameController.text.isEmpty || _maxStudentsController.text.isEmpty) return;
							final navigator = Navigator.of(context);
							await _categoryService.addCategory(
								widget.courseId,
								_nameController.text,
								_selectedGroupingMethod == 'random',
								int.parse(_maxStudentsController.text),
							);
							setState(() {
								_nameController.clear();
								_maxStudentsController.clear();
							});
							navigator.pop();
						},
						child: const Text('Guardar'),
					),
				],
			),
		);
	}

	void _showEditCategoryDialog(Category category) {
		_nameController.text = category.name;
		_selectedGroupingMethod = category.randomAssign ? 'random' : 'self';
		_maxStudentsController.text = category.studentsPerGroup.toString();

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
							initialValue: _selectedGroupingMethod,
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
				randomAssign: _selectedGroupingMethod == 'random',
				studentsPerGroup: int.parse(_maxStudentsController.text),
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
				content: Text('¿Estás seguro de que deseas eliminar "${category.name}"?'),
				actions: [
					TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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

// Additional simple placeholder pages moved here so legacy screens can forward
class CategoryPickerPage extends StatelessWidget {
	const CategoryPickerPage({super.key});

	@override
	Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Category Picker')));
}

class GroupListPage extends StatelessWidget {
	const GroupListPage({super.key});

	@override
	Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Groups')));
}

class AllGroupsPage extends StatelessWidget {
	const AllGroupsPage({super.key});

	@override
	Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('All Groups')));
}
