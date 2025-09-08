import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../../services/auth_service.dart';

class AllGroupsScreen extends StatelessWidget {
  const AllGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
  final service = CategoryService();
  final allGroups = service.getAllGroups();

    return Scaffold(
      appBar: AppBar(title: const Text('Todos los Grupos')),
      body: ListView.builder(
        itemCount: allGroups.length,
        itemBuilder: (context, index) {
          final group = allGroups[index];
          final members = group.memberUserIds.map((id) {
            try {
              final user = AuthService().users.firstWhere((u) => u.id == id);
              return user.name;
            } catch (e) {
              return id;
            }
          }).join(', ');
          return ListTile(
            title: Text(group.name),
            subtitle: Text(members.isEmpty ? 'Sin miembros' : members),
          );
        },
      ),
    );
  }
}
