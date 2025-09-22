import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/controllers/groups_controller.dart';
import 'package:proyecto_movil/features/auth/presentation/controllers/auth_controller.dart';

class GroupsListScreen extends StatelessWidget {
  final String categoryId;
  const GroupsListScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final groupsController = Get.find<GroupsController>();
    final auth = Get.find<AuthController>();
    groupsController.load(categoryId); // idempotente

    return Scaffold(
      appBar: const TopBar(title: 'Grupos'),
      body: Obx(() {
        if (groupsController.isLoading.value && groupsController.groups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = groupsController.groups;
        if (list.isEmpty) {
          return const Center(child: Text('Sin grupos'));
        }
        final currentUserId = auth.currentUserId.value;
        return RefreshIndicator(
          onRefresh: () => groupsController.refresh(),
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final g = list[index];
              final isMember = currentUserId != null && g.memberIds.contains(currentUserId);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(g.name),
                  subtitle: Text('Integrantes: ${g.memberIds.length}'),
                  trailing: currentUserId == null
                      ? null
                      : isMember
                          ? TextButton(
                              onPressed: () => groupsController.leave(g.id),
                              child: const Text('Salir'),
                            )
                          : TextButton(
                              onPressed: () => groupsController.join(g.id),
                              child: const Text('Unirse'),
                            ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
