import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import 'edit_category_screen.dart';
import 'category_detail_screen.dart';
import 'create_category_screen.dart';

class CategoriesListScreen extends StatelessWidget {
  final String courseId;
  final bool canCreate; // allow caller to disable creation (students)
  const CategoriesListScreen({super.key, required this.courseId, this.canCreate = true});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final categories = repo.categoriesBox.values.where((c) => c.courseId == courseId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final c = categories[index];
          return ListTile(
            title: Text(c.name),
            subtitle: Text('${c.randomAssign ? 'Aleatorio' : 'Libre'} - ${c.studentsPerGroup} por grupo'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditCategoryScreen(categoryId: c.id)))),
              IconButton(icon: const Icon(Icons.delete), onPressed: () async { await repo.deleteCategory(c.id); }),
            ]),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(categoryId: c.id))),
          );
        },
      ),
      floatingActionButton: canCreate ? FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCategoryScreen(courseId: courseId))),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
