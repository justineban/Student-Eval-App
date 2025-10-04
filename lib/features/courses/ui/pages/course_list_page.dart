// Course list page (enabled navigation to local detail; no external data layer)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/models/course_model.dart';
import 'course_detail_page.dart';
import 'add_course_page.dart';
import '../../ui/controllers/course_controller.dart';
import '../../../auth/ui/controllers/auth_controller.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});
  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  late final CourseController _controller;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CourseController>();
    _auth = Get.find<AuthController>();
    final teacherId = _auth.currentUser.value?.id;
    if (teacherId != null) {
      _controller.loadTeacherCourses(teacherId);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis Cursos')),
    body: Obx(() {
      if (_controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final list = _controller.courses;
      if (list.isEmpty) {
        return const Center(child: Text('Aún no tienes cursos creados'));
      }
      return ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final course = list[index];
          return ListTile(
            title: Text(course.name),
            subtitle: Text(course.description),
            trailing: Text('${course.studentIds.length} alumnos'),
            onTap: () => Get.to(() => CourseDetailPage(course: course)),
          );
        },
      );
    }),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        final created = await Get.to(() => const AddCoursePage());
        if (created is CourseModel) {
          // already added in controller, just ensure list reactive
          setState(() {});
        }
      },
      child: const Icon(Icons.add),
    ),
  );
}
