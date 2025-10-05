import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import '../../../../core/ui/widgets/list_button_card.dart';
import '../controllers/student_courses_controller.dart';
import 'course_detail_page.dart';

class EnrolledCoursesPage extends StatefulWidget {
  const EnrolledCoursesPage({super.key});

  @override
  State<EnrolledCoursesPage> createState() => _EnrolledCoursesPageState();
}

class _EnrolledCoursesPageState extends State<EnrolledCoursesPage> {
  late final StudentCoursesController _controller;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      appBar: const AppTopBar(title: 'Cursos inscritos'),
      body: Obx(() {
        final loading = _controller.loading.value;
        final courses = _controller.enrolled;
        final invites = _controller.invites;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus cursos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (loading && courses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (courses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Aún no estás inscrito en ningún curso'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = courses[i];
                    return ListButtonCard(
                      leadingIcon: Icons.class_outlined,
                      title: c.name,
                      subtitle: c.description,
                      trailingChip: '${c.studentIds.length} alumnos',
                      containerColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.75),
                      onTap: () => Get.to(() => CourseDetailPage(course: c)),
                    );
                  },
                ),

              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 12),

              // Enroll by code
              Text(
                'Inscribirme por código',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

              const SizedBox(height: 24),
              const Divider(),
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
              if (invites.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No tienes invitaciones pendientes'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = invites[i];
                    return Material(
                      color: Theme.of(
                        context,
                      ).colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.mail_outline,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              loading
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
                                          Get.off(
                                            () => CourseDetailPage(
                                              course: joined,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Aceptar'),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}

// _CourseTile removed; replaced by ListButtonCard
