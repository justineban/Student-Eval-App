import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/ui/pages/login_page.dart';
import 'features/auth/ui/controllers/auth_binding.dart';
import 'core/storage/hive_init.dart';
import 'features/courses/ui/pages/group_list_page.dart';
import 'features/courses/ui/pages/enroll_course_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Student Eval',
        initialBinding: AuthBinding(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        getPages: [
          GetPage(
            name: '/course-groups',
            page: () {
              final args = Get.arguments;
              final map = (args is Map) ? Map<String, dynamic>.from(args) : const <String, dynamic>{};
              return CourseGroupListPage(
                courseId: map['courseId'] as String? ?? '',
                categoryId: map['categoryId'] as String? ?? '',
                categoryName: map['categoryName'] as String? ?? 'Categoría',
                isManualCategory: map['isManual'] as bool? ?? true,
              );
            },
          ),
          GetPage(
            name: '/enroll',
            page: () => const EnrollCoursePage(),
          ),
        ],
        home: const LoginPage(),
      );
}
