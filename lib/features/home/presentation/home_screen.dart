import 'package:flutter/material.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/create_course_screen.dart';
import 'package:proyecto_movil/features/courses/presentation/teacher_courses_screen.dart';
import 'package:proyecto_movil/features/courses/presentation/enroll_by_code_screen.dart';
import 'package:proyecto_movil/features/courses/presentation/student_courses_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonData = [
      {
        'label': 'Crear un curso',
        'icon': Icons.add_box,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
      },
      {
        'label': 'Mis cursos',
        'icon': Icons.menu_book,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherCoursesScreen())),
      },
      {
        'label': 'Inscribirme a un curso',
        'icon': Icons.how_to_reg,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollByCodeScreen())),
      },
      {
        'label': 'Cursos inscritos',
        'icon': Icons.school,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentCoursesScreen())),
      },
    ];

    return Scaffold(
      appBar: const TopBar(title: 'Home'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 1,
          children: buttonData.map((data) {
            return InkWell(
              onTap: data['onTap'] as void Function(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(data['icon'] as IconData, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      data['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
