import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import 'enroll_by_code_screen.dart';
import 'invitations_screen.dart';
import 'student_courses_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(roleName: 'Estudiante', title: 'Home - Estudiante'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentCoursesScreen())), child: const Text('Mis Cursos')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollByCodeScreen())), child: const Text('Ingresar a Curso (código)')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationsScreen())), child: const Text('Invitaciones')),
          ],
        ),
      ),
    );
  }
}
