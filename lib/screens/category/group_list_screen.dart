import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../../services/auth_service.dart';

class GroupListScreen extends StatefulWidget {
  final String categoryId;

  const GroupListScreen({super.key, required this.categoryId});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final _service = CategoryService();

  @override
  Widget build(BuildContext context) {
    final groups = _service.getGroupsForCategory(widget.categoryId);
    final role = AuthService().currentRole;
    final currentUser = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Grupos')),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final members = group.memberUserIds.length;
          return ListTile(
            title: Text(group.name),
            subtitle: Text('$members miembros'),
            trailing: role == 'teacher'
                ? IconButton(
                    icon: const Icon(Icons.manage_accounts),
                    onPressed: () {
                      // For teachers, show member names in a dialog
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Miembros de ${group.name}'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(
                              shrinkWrap: true,
                              children: group.memberUserIds.map((id) {
                                try {
                                  final user = AuthService().users.firstWhere((u) => u.id == id);
                                  return ListTile(title: Text(user.name));
                                } catch (e) {
                                  return ListTile(title: Text(id));
                                }
                              }).toList(),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
                          ],
                        ),
                      );
                    },
                  )
                : ElevatedButton(
                    onPressed: () {
                      if (currentUser == null) return;
                      if (role != 'student') {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo estudiantes pueden unirse a grupos')));
                        return;
                      }
                      // join with status codes
                      final status = _service.addMemberToGroup(widget.categoryId, group.id, currentUser.id);
                      if (status == 1) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Te uniste al grupo')));
                        setState(() {});
                      } else if (status == 2) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya eres miembro de este grupo')));
                      } else if (status == 3) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El grupo está lleno')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo unir al grupo')));
                      }
                    },
                    child: const Text('Unirse'),
                  ),
          );
        },
      ),
    );
  }
}
