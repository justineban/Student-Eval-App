import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/teacher_view/domain/entities/group.dart';

class StudentGroupListPage extends StatelessWidget {
  final String categoryId;
  const StudentGroupListPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final category = repo.categoriesBox.get(categoryId);
    final List<Group> groups = repo.listGroupsForCategory(categoryId);

    final allowManualJoin = category != null ? !category.randomAssign : true;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grupos')),
        body: const Center(child: Text('Usuario no autenticado. Por favor inicia sesión.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Grupos')),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isMember = group.memberIds.contains(user.id);
          return ExpansionTile(
            title: Text(group.name),
            subtitle: Text('Miembros: ${group.memberIds.length}'),
            children: [
              ...group.memberIds.map((id) {
                final member = repo.usersBox.get(id);
                return ListTile(
                  title: Text(member?.name ?? 'Usuario desconocido'),
                  subtitle: Text(member?.email ?? ''),
                );
              }),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (allowManualJoin) ...[
                      if (!isMember)
                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await repo.joinGroup(group.id, user.id);
                            messenger.showSnackBar(SnackBar(content: Text(success ? 'Te has unido al grupo' : 'No se pudo unir')));
                          },
                          child: const Text('Unirse'),
                        ),
                      if (isMember)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await repo.leaveGroup(group.id, user.id);
                            messenger.showSnackBar(SnackBar(content: Text(success ? 'Has salido del grupo' : 'No se pudo salir')));
                          },
                          child: const Text('Salir'),
                        ),
                    ] else
                      const Text('Asignación aleatoria - no puedes unirte manualmente'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
