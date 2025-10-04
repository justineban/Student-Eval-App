import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Obx(
                  () => Text(
                    controller.userName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(Icons.logout),
                  onPressed: controller.logout,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Módulo de profesores'),
              const SizedBox(height: 8),
              _ActionList(
                actions: const [
                  _ActionItem(
                    label: 'Ver mis cursos',
                    actionKey: 'list_courses',
                  ),
                  _ActionItem(
                    label: 'Ver reporte de mis cursos',
                    actionKey: 'teacher_courses_report',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle('Módulo de estudiantes'),
              const SizedBox(height: 8),
              _ActionList(
                actions: const [
                  _ActionItem(
                    label: 'Ver mis cursos',
                    actionKey: 'enrolled_courses',
                  ),
                  _ActionItem(
                    label: 'Mis actividades',
                    actionKey: 'my_activities',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  );
}

class _ActionItem {
  final String label;
  final String? actionKey; // used to map to controller methods
  const _ActionItem({required this.label, this.actionKey});
}

class _ActionList extends StatelessWidget {
  final List<_ActionItem> actions;
  const _ActionList({required this.actions});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Column(
      children: actions
          .map(
            (a) => Card(
              child: ListTile(
                title: Text(a.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  switch (a.actionKey) {
                    case 'list_courses':
                      home.goToCourses();
                      break;
                    case 'enrolled_courses':
                      home.goToEnrolledCourses();
                      break;
                    case 'my_activities':
                      home.goToMyActivities();
                      break;
                    case 'teacher_courses_report':
                      home.goToTeacherCoursesReport();
                      break;
                    default:
                      // otros aun no implementados
                      break;
                  }
                },
              ),
            ),
          )
          .toList(),
    );
  }
}
