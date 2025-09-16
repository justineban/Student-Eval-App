import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/auth/presentation/controllers/auth_controller.dart';
import 'package:proyecto_movil/features/teacher_view/presentation/controllers/teacher_controller.dart';
import 'package:proyecto_movil/features/student_view/presentation/controllers/student_controller.dart';
import 'package:proyecto_movil/features/auth/presentation/pages/login_page.dart';
import 'package:proyecto_movil/features/auth/presentation/pages/register_page.dart';
import 'package:proyecto_movil/features/auth/presentation/pages/role_selection_page.dart';
import 'package:proyecto_movil/features/teacher_view/presentation/pages/teacher_home_page.dart';
import 'package:proyecto_movil/features/teacher_view/presentation/pages/teacher_courses_page.dart';
import 'package:proyecto_movil/features/student_view/presentation/pages/student_home_page.dart';
import 'package:proyecto_movil/features/student_view/presentation/pages/student_courses_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalRepository.registerAdapters();
  await LocalRepository.openBoxes();
  // load any persisted session
  LocalRepository.instance.loadCurrentUserFromSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalRepository.instance),
        ChangeNotifierProvider(create: (_) => AuthController(LocalRepository.instance)),
        ChangeNotifierProvider(create: (_) => TeacherController(LocalRepository.instance)),
        ChangeNotifierProvider(create: (_) => StudentController(LocalRepository.instance)),
      ],
      child: MaterialApp(
        title: 'Student Eval App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: LocalRepository.instance.currentUser == null ? const LoginPage() : const RoleSelectionPage(),
        routes: {
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/roles': (_) => const RoleSelectionPage(),
          '/teacher/home': (_) => const TeacherHomePage(),
          '/teacher/courses': (_) => const TeacherCoursesPage(),
          '/student/home': (_) => const StudentHomePage(),
          '/student/courses': (_) => const StudentCoursesPage(),
        },
      ),
    );
  }
}
