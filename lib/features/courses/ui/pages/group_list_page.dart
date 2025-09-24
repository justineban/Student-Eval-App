import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_controller.dart';

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
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir integrante'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          Obx(() => _controller.addingMember.value
              ? const SizedBox(width: 32, height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await _controller.addMember(groupId, name);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Añadir'),
                )),
        ],
      ),
    );
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
                                      itemBuilder: (_, j) => ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.person_outline, size: 18),
                                        title: Text(g.memberIds[j]),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () => _promptAddMember(g.id),
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
