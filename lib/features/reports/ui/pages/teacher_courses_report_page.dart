import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import '../../../../core/ui/widgets/list_button_card.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../courses/ui/controllers/course_controller.dart';
import '../../../courses/domain/models/course_model.dart';
import 'course_report_page.dart';

class TeacherCoursesReportPage extends StatefulWidget {
  const TeacherCoursesReportPage({super.key});

  @override
  State<TeacherCoursesReportPage> createState() =>
      _TeacherCoursesReportPageState();
}

class _TeacherCoursesReportPageState extends State<TeacherCoursesReportPage> {
  late final CourseController _courseCtrl;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    if (!Get.isRegistered<CourseController>()) {
      Get.put(
        CourseController(
          createCourseUseCase: Get.find(),
          getTeacherCoursesUseCase: Get.find(),
          inviteStudentUseCase: Get.find(),
          updateCourseUseCase: Get.find(),
          deleteCourseUseCase: Get.find(),
        ),
        permanent: true,
      );
    }
    _courseCtrl = Get.find<CourseController>();
    final tid = _auth.currentUser.value?.id;
    if (tid != null) {
      _courseCtrl.loadTeacherCourses(tid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Reporte de mis cursos'),
      body: Obx(() {
        final loading = _courseCtrl.loading.value;
        final courses = _courseCtrl.courses;
        if (loading) return const Center(child: CircularProgressIndicator());
        if (courses.isEmpty)
          return const Center(child: Text('No tienes cursos creados'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = courses[index];
            return ListButtonCard(
              leadingIcon: Icons.menu_book_outlined,
              title: c.name,
              subtitle: c.description,
              trailingChip: 'Ver notas',
              containerColor: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.75),
              onTap: () => _openCourseReport(c),
            );
          },
        );
      }),
    );
  }

  void _openCourseReport(CourseModel c) {
    Get.to(() => CourseReportPage(course: c));
  }
}
