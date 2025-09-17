import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final cat = repo.categoriesBox.get(categoryId);
    if (cat == null) return const Scaffold(body: Center(child: Text('Categoría no encontrada')));
    final groups = repo.groupsBox.values.where((g) => g.categoryId == categoryId).toList();

    return Scaffold(
      appBar: AppBar(title: Text(cat.name)),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final g = groups[index];
          return ListTile(title: Text(g.name), subtitle: Text('Miembros: ${g.memberIds.length}'));
        },
      ),
    );
  }
}
