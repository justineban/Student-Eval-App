import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import '../controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Scaffold(
      appBar: AppTopBar(
        title: 'Student Eval',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
          PopupMenuButton<String>(
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
            onSelected: (v) {
              if (v == 'logout') controller.logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Módulo de profesores'),
              const SizedBox(height: 8),
              _TilesGrid(
                tiles: [
                  _TileItem(
                    label: 'Ver mis cursos',
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    icon: Icons.menu_book_outlined,
                    onTap: controller.goToCourses,
                  ),
                  _TileItem(
                    label: 'Reporte de cursos',
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    icon: Icons.assessment_outlined,
                    onTap: controller.goToTeacherCoursesReport,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle('Módulo de estudiantes'),
              const SizedBox(height: 8),
              _TilesGrid(
                tiles: [
                  _TileItem(
                    label: 'Mis cursos',
                    color: Theme.of(context).colorScheme.primaryContainer,
                    icon: Icons.class_outlined,
                    onTap: controller.goToEnrolledCourses,
                  ),
                  _TileItem(
                    label: 'Mis actividades',
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    icon: Icons.event_note_outlined,
                    onTap: controller.goToMyActivities,
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

class _TilesGrid extends StatelessWidget {
  final List<_TileItem> tiles;
  const _TilesGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.45,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: tiles.map((t) => _Tile(t)).toList(),
    );
  }
}

class _TileItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TileItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _Tile extends StatelessWidget {
  final _TileItem item;
  const _Tile(this.item);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(item.icon, size: 32, color: Colors.black54),
                ),
              ),
              const Spacer(),
              Text(item.label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
