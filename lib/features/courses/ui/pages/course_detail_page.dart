import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/models/course_model.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../ui/controllers/course_controller.dart';
import '../../../assessments/ui/pages/activity_list_page.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import 'category_list_page.dart';

class CourseDetailPage extends StatefulWidget {
  final CourseModel course; // initial snapshot
  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late final AuthController _auth;
  late final CourseController _courses;
  final _inviteEmailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    _courses = Get.find<CourseController>();
  }

  @override
  void dispose() {
    _inviteEmailCtrl.dispose();
    super.dispose();
  }

  bool get _isTeacher => _auth.currentUser.value?.id == widget.course.teacherId;
  final _authLocal = HiveAuthLocalDataSource();

  CourseModel _currentCourseSnapshot() {
    // Buscar versión reactiva actualizada en la lista, si existe
    final idx = _courses.courses.indexWhere((c) => c.id == widget.course.id);
    if (idx != -1) return _courses.courses[idx];
    return widget.course;
  }

  void _showEditDialog() {
    if (!_isTeacher) return;
    final course = _currentCourseSnapshot();
    final nameCtrl = TextEditingController(text: course.name);
    final descCtrl = TextEditingController(text: course.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Obx(() {
          final saving = _courses.updating.value;
          return AlertDialog(
            title: const Text('Editar curso'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Get.back(),
                child: const Text('Cancelar'),
              ),
              saving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final updated = await _courses.updateCourse(
                          id: course.id,
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          teacherId: course.teacherId,
                        );
                        if (!mounted) return;
                        if (updated != null) {
                          Get.back();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Curso actualizado')),
                          );
                        } else {
                          final msg =
                              _courses.error.value ?? 'No se pudo actualizar';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                      child: const Text('Guardar'),
                    ),
            ],
          );
        });
      },
    );
  }

  void _confirmDelete() {
    if (!_isTeacher) return;
    final course = _currentCourseSnapshot();
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Obx(() {
          final deleting = _courses.deleting.value;
          return AlertDialog(
            title: const Text('Eliminar curso'),
            content: Text(
              '¿Deseas eliminar definitivamente "${course.name}"? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              deleting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: () async {
                        final ok = await _courses.deleteCourse(
                          id: course.id,
                          teacherId: course.teacherId,
                        );
                        if (!mounted) return;
                        if (ok) {
                          // Close dialog and this page
                          Get.back(result: true);
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                          Get.snackbar(
                            'Curso eliminado',
                            '"${course.name}" se eliminó correctamente',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } else {
                          final msg =
                              _courses.error.value ?? 'No se pudo eliminar';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Eliminar'),
                    ),
            ],
          );
        });
      },
    );
  }

  void _onInvite() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _inviteEmailCtrl.text.trim();
    final course = _currentCourseSnapshot();
    await _courses.inviteStudent(
      courseId: course.id,
      teacherId: course.teacherId,
      email: email,
    );
    if (_courses.inviteError.value == null) {
      _inviteEmailCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invitación registrada')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_courses.inviteError.value!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle Curso')),
      body: Obx(() {
        final course = _currentCourseSnapshot();
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(course.description),
                    const SizedBox(height: 12),
                    FutureBuilder(
                      future: _authLocal.fetchUserById(course.teacherId),
                      builder: (context, snapshot) {
                        final name = snapshot.data?.name ?? 'Docente';
                        return Text(
                          'Docente: $name',
                          style: const TextStyle(color: Colors.grey),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_isTeacher)
                          Text(
                            'Código: ${course.registrationCode}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        const Spacer(),
                        if (_isTeacher) ...[
                          IconButton(
                            onPressed: _showEditDialog,
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            onPressed: _confirmDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Eliminar',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Estudiantes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minHeight: 120,
                        maxHeight: 260,
                      ),
                      child: course.studentIds.isEmpty
                          ? const Center(child: Text('Sin estudiantes todavía'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: course.studentIds.length,
                              itemBuilder: (_, i) {
                                final studentId = course.studentIds[i];
                                return FutureBuilder(
                                  future: _authLocal.fetchUserById(studentId),
                                  builder: (context, snapshot) {
                                    final isMe =
                                        _auth.currentUser.value?.id ==
                                        studentId;
                                    final displayName =
                                        snapshot.data?.name ?? 'Estudiante';
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.person_outline),
                                      title: Text(
                                        isMe
                                            ? '$displayName (tú)'
                                            : displayName,
                                      ),
                                      subtitle: snapshot.hasData
                                          ? Text(snapshot.data!.email)
                                          : null,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    // withOpacity deprecated; replace using alpha value 0.05 -> 13/255 ~ 0x0D
                    color: const Color(0x0D000000),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.to(
                              () => const ActivityListPage(),
                              arguments: {'courseId': course.id},
                            ),
                            icon: const Icon(Icons.task_outlined),
                            label: const Text('Ver actividades'),
                          ),
                        ),
                        if (_isTeacher) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Get.to(
                                () => const CategoryListPage(),
                                arguments: {'courseId': course.id},
                              ),
                              icon: const Icon(Icons.category_outlined),
                              label: const Text('Ver categorías'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isTeacher) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Invitar estudiante',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _inviteEmailCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Requerido';
                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Email inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Obx(
                              () => _courses.inviteLoading.value
                                  ? const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _onInvite,
                                      child: const Text('Invitar'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (course.invitations.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Invitaciones pendientes (${course.invitations.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: course.invitations.length,
                            itemBuilder: (_, i) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.indigo.shade200,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.indigo.shade50,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.mail_outline, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    course.invitations[i],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
