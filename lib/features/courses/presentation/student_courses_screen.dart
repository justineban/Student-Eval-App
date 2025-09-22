import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_movil/core/entities/course.dart' as legacy;
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/course_detail_screen.dart';
import 'controllers/student_courses_controller.dart';
import '../../auth/presentation/controllers/auth_controller.dart';


class StudentCoursesScreen extends StatelessWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentCoursesController>();
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: const TopBar(title: 'Mis Cursos'),
      body: Obx(() {
        if (!auth.isLoggedIn) {
          return const Center(child: Text('No autenticado'));
        }
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = controller.courses;
        if (list.isEmpty) {
          return const Center(child: Text('Sin cursos'));
        }
        return RefreshIndicator(
          onRefresh: () => controller.refreshAll(),
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final course = list[index];
              final legacyCourse = legacy.Course(
                id: course.id,
                name: course.name,
                description: course.description,
                teacherId: course.teacherId,
                registrationCode: course.registrationCode,
                studentIds: course.studentIds,
                invitations: course.invitations,
              );
              return ListTile(
                title: Text(course.name),
                subtitle: Text('Docente: ${course.teacherId}'), // Pending teacher name mapping
                onTap: () => Get.to(() => CourseDetailScreen(course: legacyCourse)),
              );
            },
          ),
        );
      }),
    );
  }
}
