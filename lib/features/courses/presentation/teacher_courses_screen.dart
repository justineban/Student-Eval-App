import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_movil/core/entities/course.dart' as legacy;
import '../../../core/widgets/top_bar.dart';
import 'create_course_screen.dart';
import 'course_detail_screen.dart';
import 'controllers/teacher_courses_controller.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class TeacherCoursesScreen extends StatelessWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
  final controller = Get.find<TeacherCoursesController>();
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
        final myCourses = controller.courses;
        if (myCourses.isEmpty) {
          return const Center(child: Text('Sin cursos'));
        }
        return RefreshIndicator(
          onRefresh: () => controller.refreshCourses(),
          child: ListView.builder(
            itemCount: myCourses.length,
            itemBuilder: (context, index) {
              final course = myCourses[index];
              return ListTile(
                title: Text(course.name),
                subtitle: Text('${course.studentIds.length} estudiantes'),
                onTap: () {
                  final legacyCourse = legacy.Course(
                    id: course.id,
                    name: course.name,
                    description: course.description,
                    teacherId: course.teacherId,
                    registrationCode: course.registrationCode,
                    studentIds: course.studentIds,
                    invitations: course.invitations,
                  );
                  Get.to(() => CourseDetailScreen(course: legacyCourse));
                },
              );
            },
          ),
        );
      }),
      floatingActionButton: Obx(() => auth.isLoggedIn ? FloatingActionButton(
        onPressed: () => Get.to(() => const CreateCourseScreen()),
        child: const Icon(Icons.add),
      ) : const SizedBox.shrink()),
    );
  }
}
