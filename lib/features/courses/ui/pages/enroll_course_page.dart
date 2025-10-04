import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_courses_controller.dart';
import 'course_detail_page.dart';

class EnrollCoursePage extends StatefulWidget {
  const EnrollCoursePage({super.key});

  @override
  State<EnrollCoursePage> createState() => _EnrollCoursePageState();
}

class _EnrollCoursePageState extends State<EnrollCoursePage> {
  final _codeCtrl = TextEditingController();
  late final StudentCoursesController _controller;

  @override
  void initState() {
    super.initState();
    // Ensure controller is registered (fallback in case initial binding didn't register it yet)
    if (!Get.isRegistered<StudentCoursesController>()) {
      Get.put(
        StudentCoursesController(
          joinByCodeUseCase: Get.find(),
          getStudentCoursesUseCase: Get.find(),
          getInvitedCoursesUseCase: Get.find(),
          acceptInvitationUseCase: Get.find(),
        ),
        permanent: true,
      );
    }
    _controller = Get.find<StudentCoursesController>();
    // Load invitations initially
    _controller.refreshData();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscribirme a un curso')),
      body: Obx(() {
        final loading = _controller.loading.value;
        final invites = _controller.invites;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Usar código de registro',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Código',
                        hintText: 'ABC123',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  loading
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final course = await _controller.joinByCode(
                              _codeCtrl.text,
                            );
                            if (course != null) {
                              _codeCtrl.clear();
                              // Go directly to course detail after successful join
                              Get.off(() => CourseDetailPage(course: course));
                            } else {
                              final msg =
                                  _controller.error.value ?? 'Código inválido';
                              Get.snackbar(
                                'No se pudo inscribir',
                                msg,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          child: const Text('Unirme'),
                        ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('o'),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Invitaciones'),
                  const SizedBox(width: 8),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  IconButton(
                    onPressed: _controller.refreshData,
                    tooltip: 'Actualizar',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: invites.isEmpty
                    ? const Center(
                        child: Text('No tienes invitaciones pendientes'),
                      )
                    : ListView.builder(
                        itemCount: invites.length,
                        itemBuilder: (_, i) {
                          final c = invites[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.mail_outline),
                              title: Text(c.name),
                              subtitle: Text(c.description),
                              trailing: loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () async {
                                        final joined = await _controller
                                            .acceptInvite(c.id);
                                        if (joined != null) {
                                          // Navigate to detail immediately after accepting invitation
                                          Get.off(
                                            () => CourseDetailPage(
                                              course: joined,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Aceptar'),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
