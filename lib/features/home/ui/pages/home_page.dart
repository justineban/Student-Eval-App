import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('Inicio - ${controller.userName}')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.logout,
            tooltip: 'Cerrar sesión',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, ${controller.userName}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text('Selecciona un módulo:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HomeCard(
                  icon: Icons.book,
                  label: 'Cursos',
                  onTap: controller.goToCourses,
                ),
                _HomeCard(
                  icon: Icons.assessment,
                  label: 'Evaluaciones',
                  onTap: controller.goToAssessments,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Esta pantalla centralizará acceso a Courses y Assessments.'),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HomeCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
        ),
      );
}
