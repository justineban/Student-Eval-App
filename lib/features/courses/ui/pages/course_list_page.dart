// Course list page (enabled navigation to local detail; no external data layer)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
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
    appBar: const AppTopBar(title: 'Mis Cursos'),
    body: Obx(() {
      if (_controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final list = _controller.courses;
      if (list.isEmpty) {
        return const Center(child: Text('Aún no tienes cursos creados'));
      }
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final course = list[index];
          final hasDesc = course.description.trim().isNotEmpty;
          return Material(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Get.to(() => CourseDetailPage(course: course)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasDesc) ...[
                            const SizedBox(height: 4),
                            Text(
                              course.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onPrimaryContainer.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${course.studentIds.length} alumnos',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
                  ],
                ),
              ),
            ),
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
