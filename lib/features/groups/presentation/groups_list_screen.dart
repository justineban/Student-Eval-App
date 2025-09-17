import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/user.dart';
import 'package:proyecto_movil/core/entities/group.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';

class GroupsListScreen extends StatefulWidget {
  final String categoryId;
  const GroupsListScreen({super.key, required this.categoryId});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    // Ya no se regeneran los grupos automáticamente al entrar
  }

  Future<void> _regenerateGroups() async {
    final repo = Provider.of<LocalRepository>(context, listen: false);
    await repo.createGroupsForCategory(widget.categoryId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final category = repo.categoriesBox.get(widget.categoryId);
    if (category == null) {
      return const Scaffold(body: Center(child: Text('Categoría no encontrada')));
    }
  var groups = repo.listGroupsForCategory(widget.categoryId);
    final currentUser = repo.currentUser;
    final isRandom = category.randomAssign;
    final isCreator = currentUser != null && currentUser.id == repo.coursesBox.get(category.courseId)?.teacherId;
    // Verificar si el usuario ya pertenece a algún grupo de la categoría
    String? joinedGroupId;
    if (currentUser != null) {
      for (final g in groups) {
        if (g.memberIds.contains(currentUser.id)) {
          joinedGroupId = g.id;
          break;
        }
      }
    }
    // Si la categoría es libre y hay un nuevo estudiante sin grupo, crear un nuevo grupo si todos están llenos
    if (!isRandom && currentUser != null && joinedGroupId == null && !isCreator) {
      final allInGroups = groups.expand((g) => g.memberIds).toSet();
      if (!allInGroups.contains(currentUser.id)) {
        final allFull = groups.every((g) => g.memberIds.length >= category.studentsPerGroup);
        if (allFull) {
          final newGroupId = '${category.id}_g${groups.length + 1}';
          final newGroup = Group(
            id: newGroupId,
            categoryId: category.id,
            name: 'Grupo ${groups.length + 1}',
            memberIds: [],
          );
          repo.groupsBox.put(newGroupId, newGroup);
          groups = repo.listGroupsForCategory(widget.categoryId);
        }
      }
    }
    return Scaffold(
    appBar: const TopBar(title: 'Grupos'),
      body: RefreshIndicator(
        onRefresh: _regenerateGroups,
        child: ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final repo = Provider.of<LocalRepository>(context, listen: false);
            final members = group.memberIds.map((id) => repo.usersBox.get(id)).whereType<User>().toList();
            final canShowJoin = !isRandom && !isCreator && joinedGroupId == null && currentUser != null && group.memberIds.length < category.studentsPerGroup;
            final canShowLeave = !isRandom && !isCreator && joinedGroupId == group.id && currentUser != null;
            final canShowDelete = isCreator && !isRandom; // Docente y libre
            return Stack(
              children: [
                _GroupExpansionTile(
                  groupName: group.name,
                  memberCount: group.memberIds.length,
                  members: members,
                  showJoinButton: canShowJoin,
                  onJoin: () async {
                    if (currentUser != null && joinedGroupId == null) {
                      await repo.joinGroup(group.id, currentUser.id);
                      setState(() {});
                    }
                  },
                  showLeaveButton: canShowLeave,
                  onLeave: () async {
                    if (currentUser != null && joinedGroupId == group.id) {
                      await repo.leaveGroup(group.id, currentUser.id);
                      setState(() {});
                    }
                  },
                ),
                if (canShowDelete)
                  Positioned(
                    top: 32, // Centrado verticalmente con la flecha
                    right: 48, // Más a la izquierda
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar grupo',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar grupo'),
                            content: Text('¿Seguro que deseas eliminar el grupo "${group.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await repo.deleteGroup(group.id);
                          setState(() {});
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: (isCreator && !isRandom)
          ? FloatingActionButton(
              onPressed: () async {
                final newGroupId = '${category.id}_g${groups.length + 1}';
                final newGroup = Group(
                  id: newGroupId,
                  categoryId: category.id,
                  name: 'Grupo ${groups.length + 1}',
                  memberIds: [],
                );
                await repo.groupsBox.put(newGroupId, newGroup);
                setState(() {});
              },
              tooltip: 'Crear grupo vacío',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}


class _GroupExpansionTile extends StatefulWidget {
  final String groupName;
  final int memberCount;
  final List<User> members;
  final bool showJoinButton;
  final VoidCallback? onJoin;
  final bool showLeaveButton;
  final VoidCallback? onLeave;
  const _GroupExpansionTile({
    required this.groupName,
    required this.memberCount,
    required this.members,
    this.showJoinButton = false,
    this.onJoin,
    this.showLeaveButton = false,
    this.onLeave,
  });

  @override
  State<_GroupExpansionTile> createState() => _GroupExpansionTileState();
}

class _GroupExpansionTileState extends State<_GroupExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Container(
            decoration: BoxDecoration(
              color: _expanded ? Colors.grey : null,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.groupName, style: Theme.of(context).textTheme.titleMedium),
                      Text('Integrantes: ${widget.memberCount}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (widget.showJoinButton)
                  ElevatedButton(
                    onPressed: widget.onJoin,
                    child: const Text('Unirse'),
                  ),
                if (widget.showLeaveButton)
                  OutlinedButton(
                    onPressed: widget.onLeave,
                    child: const Text('Salir'),
                  ),
              ],
            ),
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _expanded = expanded;
            });
          },
          children: [
            SizedBox(
              height: 150,
              child: widget.members.isEmpty
                  ? const Center(child: Text('Sin integrantes'))
                  : DragTarget<Map<String, dynamic>>(
                      onWillAccept: (data) {
                        final repo = Provider.of<LocalRepository>(context, listen: false);
                        final currentUser = repo.currentUser;
                        final group = repo.groupsBox.values.firstWhere(
                          (g) => g.name == widget.groupName,
                          orElse: () => Group(id: '', categoryId: '', name: ''),
                        );
                        final category = repo.categoriesBox.get(group.categoryId);
                        final isCreator = currentUser != null && category != null && repo.coursesBox.get(category.courseId)?.teacherId == currentUser.id;
                        return isCreator && data != null && data['fromGroupId'] != group.id;
                      },
                      onAccept: (data) async {
                        final repo = Provider.of<LocalRepository>(context, listen: false);
                        final userId = data['userId'] as String;
                        final fromGroupId = data['fromGroupId'] as String;
                        final group = repo.groupsBox.values.firstWhere(
                          (g) => g.name == widget.groupName,
                          orElse: () => Group(id: '', categoryId: '', name: ''),
                        );
                        if (group.id.isNotEmpty) {
                          await repo.leaveGroup(fromGroupId, userId);
                          await repo.joinGroup(group.id, userId);
                          setState(() {});
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: widget.members.length,
                                itemBuilder: (context, idx) {
                                  final user = widget.members[idx];
                                  final repo = Provider.of<LocalRepository>(context, listen: false);
                                  final currentUser = repo.currentUser;
                                  final group = repo.groupsBox.values.firstWhere(
                                    (g) => g.name == widget.groupName,
                                    orElse: () => Group(id: '', categoryId: '', name: ''),
                                  );
                                  final category = repo.categoriesBox.get(group.categoryId);
                                  final isCreator = currentUser != null && category != null && repo.coursesBox.get(category.courseId)?.teacherId == currentUser.id;
                                  return _buildStudentTile(user, isCreator, group, repo);
                                },
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final repo = Provider.of<LocalRepository>(context, listen: false);
                                final currentUser = repo.currentUser;
                                final group = repo.groupsBox.values.firstWhere(
                                  (g) => g.name == widget.groupName,
                                  orElse: () => Group(id: '', categoryId: '', name: ''),
                                );
                                final category = repo.categoriesBox.get(group.categoryId);
                                final isCreator = currentUser != null && category != null && repo.coursesBox.get(category.courseId)?.teacherId == currentUser.id;
                                if (!isCreator) return const SizedBox.shrink();
                                // Obtener estudiantes de otros grupos o sin grupo
                                final allGroups = repo.listGroupsForCategory(group.categoryId);
                                final allStudents = repo.coursesBox.get(category.courseId)?.studentIds ?? <String>[];
                                // Mostrar solo estudiantes que no tienen grupo
                                final studentsWithGroup = allGroups.expand((g) => g.memberIds).toSet();
                                final availableUserIds = allStudents.where((id) => !studentsWithGroup.contains(id)).toList();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Agregar estudiante'),
                                    onPressed: availableUserIds.isEmpty
                                        ? null
                                        : () async {
                                            final selectedUserId = await showDialog<String>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Agregar estudiante al grupo'),
                                                content: SizedBox(
                                                  width: 300,
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: availableUserIds.length,
                                                    itemBuilder: (ctx2, idx) {
                                                      final u = repo.usersBox.get(availableUserIds[idx]);
                                                      if (u == null) return const SizedBox.shrink();
                                                      return ListTile(
                                                        title: Text(u.name),
                                                        subtitle: Text(u.email),
                                                        onTap: () => Navigator.of(ctx).pop(u.id),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (selectedUserId != null && selectedUserId.isNotEmpty) {
                                              if (group.memberIds.length >= category.studentsPerGroup) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Este grupo está lleno')),
                                                  );
                                                }
                                                return;
                                              }
                                              // Si el estudiante ya está en otro grupo, moverlo
                                              Group? fromGroup;
                                              try {
                                                fromGroup = allGroups.firstWhere((g) => g.memberIds.contains(selectedUserId));
                                              } catch (_) {
                                                fromGroup = null;
                                              }
                                              if (fromGroup != null) {
                                                await repo.moveStudentToGroup(userId: selectedUserId, fromGroupId: fromGroup.id, toGroupId: group.id);
                                              } else {
                                                await repo.joinGroup(group.id, selectedUserId);
                                              }
                                              setState(() {});
                                            }
                                          },
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(User user, bool isCreator, Group group, LocalRepository repo) {
    return Builder(
      builder: (context) {
        return LongPressDraggable<Map<String, dynamic>>(
          data: {'userId': user.id, 'fromGroupId': group.id},
          feedback: Material(
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(8),
              color: Colors.blueAccent,
              child: Row(
                children: [
                  Expanded(child: Text(user.name, style: const TextStyle(color: Colors.white))),
                  if (isCreator)
                    Icon(Icons.remove_circle, color: Colors.white.withOpacity(0.7)),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _studentListTile(user, isCreator, group, repo, ignorePointer: true),
          ),
          child: _studentListTile(user, isCreator, group, repo, ignorePointer: false),
        );
      },
    );
  }

  Widget _studentListTile(User user, bool isCreator, Group group, LocalRepository repo, {bool ignorePointer = false}) {
    return ListTile(
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: isCreator
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AbsorbPointer(
                  absorbing: ignorePointer,
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    tooltip: 'Sacar del grupo',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sacar estudiante'),
                          content: Text('¿Seguro que deseas sacar a ${user.name} del grupo?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sacar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && group.id.isNotEmpty) {
                        await repo.leaveGroup(group.id, user.id);
                        setState(() {});
                      }
                    },
                  ),
                ),
                AbsorbPointer(
                  absorbing: ignorePointer,
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                    tooltip: 'Mover a otro grupo',
                    onPressed: () async {
                      final allGroups = repo.listGroupsForCategory(group.categoryId);
                      final otherGroups = allGroups.where((g) => g.id != group.id).toList();
                      final selectedGroupId = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Mover estudiante'),
                          content: SizedBox(
                            width: 300,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: otherGroups.length,
                              itemBuilder: (ctx2, idx) {
                                final g = otherGroups[idx];
                                return ListTile(
                                  title: Text(g.name),
                                  subtitle: Text('Integrantes: ${g.memberIds.length}'),
                                  onTap: () => Navigator.of(ctx).pop(g.id),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      );
                      if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
                        final toGroup = allGroups.firstWhere((g) => g.id == selectedGroupId);
                        final category = repo.categoriesBox.get(group.categoryId);
                        if (toGroup.memberIds.length >= (category?.studentsPerGroup ?? 0)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Este grupo está lleno')),
                            );
                          }
                          return;
                        }
                        await repo.moveStudentToGroup(userId: user.id, fromGroupId: group.id, toGroupId: selectedGroupId);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
