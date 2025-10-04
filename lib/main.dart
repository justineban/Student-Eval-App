import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/ui/controllers/auth_binding.dart';
import 'core/storage/hive_init.dart';
import 'features/courses/ui/pages/group_list_page.dart';
import 'features/courses/ui/pages/enroll_course_page.dart';
import 'core/navigation/splash_page.dart';

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
    theme: _appTheme,
    getPages: [
      GetPage(
        name: '/course-groups',
        page: () {
          final args = Get.arguments;
          final map = (args is Map)
              ? Map<String, dynamic>.from(args)
              : const <String, dynamic>{};
          return CourseGroupListPage(
            courseId: map['courseId'] as String? ?? '',
            categoryId: map['categoryId'] as String? ?? '',
            categoryName: map['categoryName'] as String? ?? 'Categoría',
            isManualCategory: map['isManual'] as bool? ?? true,
          );
        },
      ),
      GetPage(name: '/enroll', page: () => const EnrollCoursePage()),
    ],
    home: const SplashPage(),
  );
}

final _appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF006B5E), // teal profundo
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF6F8FA),
  textTheme: Typography.blackMountainView.copyWith(
    headlineMedium: const TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    titleLarge: const TextStyle(fontWeight: FontWeight.w700),
    titleMedium: const TextStyle(fontWeight: FontWeight.w600),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF7F9FA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    margin: const EdgeInsets.all(8),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  ),
);
