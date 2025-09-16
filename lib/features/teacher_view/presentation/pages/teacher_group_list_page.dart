import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';

class TeacherGroupListPage extends StatelessWidget {
  final String categoryId;

  const TeacherGroupListPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context, listen: false);
    final groups = repo.listGroupsForCategory(categoryId);

    return Scaffold(
      appBar: AppBar(title: const Text('Grupos de Categoría')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final created = await repo.createGroupsForCategory(categoryId);
              messenger.showSnackBar(SnackBar(content: Text('Grupos generados: ${created.length}')));
            },
            child: const Text('Generar Grupos'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final g = groups[index];
                return ExpansionTile(
                  title: Text(g.name),
                  subtitle: Text('Miembros: ${g.memberIds.length}'),
                  children: [
                    ...g.memberIds.map((id) {
                      final member = repo.usersBox.get(id);
                      return ListTile(
                        title: Text(member?.name ?? 'Usuario desconocido'),
                        subtitle: Text(member?.email ?? ''),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
