import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import '../../../domain/entities/category.dart';
// domain group import not needed here

class StudentCourseDetailScreen extends StatelessWidget {
  final String courseId;
  const StudentCourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final categories = repo.categoriesBox.values.where((c) => c.courseId == courseId).toList();
    final user = repo.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('No user')));

    return Scaffold(
      appBar: AppBar(title: const Text('Curso')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final Category cat = categories[index];
          final groups = repo.listGroupsForCategory(cat.id);
          return ExpansionTile(
            title: Text(cat.name),
            subtitle: Text(cat.randomAssign ? 'Aleatorio' : 'Auto-asignado'),
            children: groups.map((g) {
              final memberNames = g.memberIds.map((id) => repo.usersBox.get(id)?.name ?? id).join(', ');
              final isMember = g.memberIds.contains(user.id);
              return ListTile(
                title: Text(g.name),
                subtitle: Text(memberNames.isEmpty ? 'Vacío' : memberNames),
                trailing: ElevatedButton(
                  onPressed: () async {
                    if (isMember) {
                      await repo.leaveGroup(g.id, user.id);
                    } else {
                      await repo.joinGroup(g.id, user.id);
                    }
                  },
                  child: Text(isMember ? 'Salir' : 'Unirse'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
