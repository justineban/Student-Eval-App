import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_courses_controller.dart';
import '../../domain/models/course_model.dart';
import 'course_detail_page.dart';

class EnrolledCoursesPage extends StatefulWidget {
  const EnrolledCoursesPage({super.key});

  @override
  State<EnrolledCoursesPage> createState() => _EnrolledCoursesPageState();
}

class _EnrolledCoursesPageState extends State<EnrolledCoursesPage> {
  late final StudentCoursesController _controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StudentCoursesController>()) {
      Get.put(StudentCoursesController(
        joinByCodeUseCase: Get.find(),
        getStudentCoursesUseCase: Get.find(),
        getInvitedCoursesUseCase: Get.find(),
        acceptInvitationUseCase: Get.find(),
      ), permanent: true);
    }
    _controller = Get.find<StudentCoursesController>();
    _controller.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos inscritos'),
        actions: [
          IconButton(
            tooltip: 'Inscribirme a un curso',
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed('/enroll'),
          )
        ],
      ),
      body: Obx(() {
        final loading = _controller.loading.value;
        final courses = _controller.enrolled;
        if (loading && courses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Aún no estás inscrito en ningún curso'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/enroll'),
                  icon: const Icon(Icons.add),
                  label: const Text('Inscribirme a un curso'),
                )
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: courses.length,
          itemBuilder: (_, i) => _CourseTile(course: courses[i]),
        );
      }),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final CourseModel course;
  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(course.name),
        subtitle: Text(course.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => CourseDetailPage(course: course)),
      ),
    );
  }
}
