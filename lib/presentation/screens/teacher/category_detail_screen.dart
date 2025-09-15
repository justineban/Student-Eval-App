import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final category = repo.categoriesBox.get(widget.categoryId);
    if (category == null) return Scaffold(body: Center(child: Text('Categoría no encontrada')));
    final groups = repo.listGroupsForCategory(category.id);

    return Scaffold(
      appBar: AppBar(title: Text('Categoría - ${category.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método: ${category.randomAssign ? 'Aleatorio' : 'Libre selección'}'),
            Text('Tamaño por grupo: ${category.studentsPerGroup}'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async { await repo.createGroupsForCategory(category.id); if (!mounted) return; setState(() {}); }, child: const Text('(Re)Generar grupos')),
            const SizedBox(height: 12),
            const Text('Grupos:'),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final g = groups[index];
                  return ExpansionTile(
                    title: Text(g.name),
                    children: g.memberIds.map((id) {
                      final user = repo.usersBox.get(id);
                      return ListTile(title: Text(user?.name ?? 'Usuario desconocido'), subtitle: Text(user?.email ?? ''));
                    }).toList(),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
