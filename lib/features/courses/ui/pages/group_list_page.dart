import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_controller.dart';
import '../controllers/course_controller.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';

class CourseGroupListPage extends StatefulWidget {
  final String courseId;
  final String categoryId;
  final String categoryName;
  const CourseGroupListPage({super.key, required this.courseId, required this.categoryId, required this.categoryName});

  @override
  State<CourseGroupListPage> createState() => _CourseGroupListPageState();
}

class _CourseGroupListPageState extends State<CourseGroupListPage> {
  late final CourseGroupController _controller;
  @override
  void initState() { super.initState(); _controller = Get.find<CourseGroupController>(); _controller.load(widget.categoryId); }

  Future<void> _createAuto() async { await _controller.create(courseId: widget.courseId, categoryId: widget.categoryId); }

  void _promptAddMember(String groupId) {
    final coursesCtrl = Get.find<CourseController>();
    final course = coursesCtrl.courses.firstWhereOrNull((c) => c.id == widget.courseId);
    final allStudents = (course?.studentIds ?? []).toList();
    // Excluir alumnos ya asignados a cualquier grupo de esta categoría
    final assigned = _controller.groups.expand((g) => g.memberIds).toSet();
    final available = allStudents.where((s) => !assigned.contains(s)).toList();
    if (available.isEmpty) {
      Get.snackbar('Sin alumnos disponibles', 'No hay estudiantes registrados para agregar');
      return;
    }
    String? selected = available.first;
    final authLocal = HiveAuthLocalDataSource();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir integrante'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => DropdownButtonFormField<String>(
            initialValue: selected,
            items: [
              for (final id in available)
                DropdownMenuItem(
                  value: id,
                  child: FutureBuilder(
                    future: authLocal.fetchUserById(id),
                    builder: (context, snapshot) {
                      final name = snapshot.data?.name ?? id;
                      return Text(name);
                    },
                  ),
                ),
            ],
            onChanged: (v) => setSt(() => selected = v),
            decoration: const InputDecoration(labelText: 'Alumno', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          Obx(() => _controller.addingMember.value
              ? const SizedBox(width: 32, height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: () async {
                    if (selected == null) return;
                    await _controller.addMember(groupId, selected!);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Añadir'),
                )),
        ],
      ),
    );
  }

  Future<void> _promptMoveMember({required String fromGroupId, required String memberName}) async {
  final groups = _controller.groups.where((g) => g.id != fromGroupId && _controller.canAddToGroup(g.id)).toList();
    if (groups.isEmpty) {
      Get.snackbar('Sin opciones', 'No hay grupos disponibles con cupo');
      return;
    }
    String? selectedId = groups.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mover integrante'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => DropdownButtonFormField<String>(
            initialValue: selectedId,
            items: [
              for (final g in groups)
                DropdownMenuItem(
                  value: g.id,
                  child: Text('${g.name} (${g.memberIds.length}/${_controller.categoryMaxFor(g.categoryId)})'),
                ),
            ],
            onChanged: (v) => setSt(() => selectedId = v),
            decoration: const InputDecoration(labelText: 'Grupo destino'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          Obx(() => _controller.movingMember.value
              ? const SizedBox(width: 32, height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : ElevatedButton(
                  onPressed: () async {
                    if (selectedId == null) return;
                    final res = await _controller.moveMember(fromGroupId: fromGroupId, toGroupId: selectedId!, memberName: memberName);
                    if (res != null && mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Mover'),
                )),
        ],
      ),
    );
    if (ok == true) {
      Get.snackbar('Integrante movido', '$memberName fue movido');
    }
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text('¿Eliminar "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          Obx(() => _controller.deleting.value
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: () async {
                    final ok = await _controller.delete(id);
                    if (ok && mounted) Navigator.pop(context);
                  },
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grupos • ${widget.categoryName}')),
      body: Obx(() {
        if (_controller.loading.value) return const Center(child: CircularProgressIndicator());
        if (_controller.groups.isEmpty) return const Center(child: Text('Aún no hay grupos'));
        return ListView.builder(
          itemCount: _controller.groups.length,
          itemBuilder: (_, i) {
            final g = _controller.groups[i];
            return Obx(() {
              final expanded = _controller.expandedGroupIds.contains(g.id);
              return Column(
                children: [
                  ListTile(
                    title: Text(g.name),
                    // Left side icon is visual only (no tap action)
                    leading: Icon(expanded ? Icons.expand_less : Icons.group_outlined),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Single right-side button to toggle members panel
                        IconButton(
                          icon: const Icon(Icons.people_outline),
                          tooltip: expanded ? 'Ocultar integrantes' : 'Ver integrantes',
                          onPressed: () => _controller.toggleExpanded(g.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(g.id, g.name),
                        ),
                      ],
                    ),
                  ),
                  if (expanded)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: g.memberIds.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('Sin integrantes todavía', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  )
                                : Scrollbar(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: g.memberIds.length,
                                      itemBuilder: (_, j) {
                                        final member = g.memberIds[j];
                                        final authLocal = HiveAuthLocalDataSource();
                                        return FutureBuilder(
                                          future: authLocal.fetchUserById(member),
                                          builder: (context, snapshot) {
                                            final display = snapshot.data?.name ?? member;
                                            return ListTile(
                                              dense: true,
                                              leading: const Icon(Icons.person_outline, size: 18),
                                              title: Text(display),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.swap_horiz_outlined),
                                                tooltip: 'Cambiar de grupo',
                                                onPressed: () => _promptMoveMember(fromGroupId: g.id, memberName: display),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                tooltip: 'Quitar del grupo',
                                                onPressed: () async {
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text('Quitar integrante'),
                                                      content: Text('¿Quitar "$display" de ${g.name}?'),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok == true) {
                                                    await _controller.removeMember(g.id, member);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: !_controller.canAddToGroup(g.id) ? null : () => _promptAddMember(g.id),
                              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                              label: const Text('Añadir integrante'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                ],
              );
            });
          },
        );
      }),
      floatingActionButton: Obx(() => FloatingActionButton(
            onPressed: _controller.creating.value ? null : _createAuto,
            child: _controller.creating.value
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
          )),
    );
  }
}
