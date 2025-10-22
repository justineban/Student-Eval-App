import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/ui/controllers/auth_binding.dart';
import 'core/storage/hive_init.dart';
import 'features/courses/ui/pages/group_list_page.dart';
import 'features/courses/ui/pages/enroll_course_page.dart';
import 'core/navigation/splash_page.dart';

import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();

  // Global Flutter error handler to print stacktraces to console
  FlutterError.onError = (FlutterErrorDetails details) {
    // Print to console (visible in debug console)
    // ignore: avoid_print
    print('FlutterError caught: ${details.exception}');
    // ignore: avoid_print
    print(details.stack);
    FlutterError.presentError(details);
  };

  // Catch any uncaught errors in the zone
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stack) {
      // ignore: avoid_print
      print('Uncaught zone error: $error');
      // ignore: avoid_print
      print(stack);
    },
  );
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
  // Paleta académica: índigo/azul con acentos cyan
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3F51B5), // Indigo 500
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF7F9FC),
  textTheme: Typography.blackMountainView.copyWith(
    displaySmall: const TextStyle(fontWeight: FontWeight.w700),
    headlineMedium: const TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
    titleLarge: const TextStyle(fontWeight: FontWeight.w700),
    titleMedium: const TextStyle(fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(height: 1.3),
    bodyMedium: const TextStyle(height: 1.35),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 2,
  ),
  dividerTheme: DividerThemeData(
    color: const Color(0xFFE6EAF0),
    space: 1,
    thickness: 1,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    margin: const EdgeInsets.all(8),
    elevation: 1,
    shadowColor: Colors.black.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF4F7FA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: const Color(0xFF3F51B5).withValues(alpha: 0.8),
        width: 1.5,
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: Color(0xFFE1E6ED)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      elevation: 0,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  chipTheme: ChipThemeData(
    shape: StadiumBorder(side: const BorderSide(color: Color(0xFFE1E6ED))),
    backgroundColor: const Color(0xFFF4F7FA),
    selectedColor: const Color(0xFFE3E7FB),
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    visualDensity: VisualDensity(vertical: -1),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 2),
);
