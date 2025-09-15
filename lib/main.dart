import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'data/local/local_repository.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/role_selection_screen.dart';
import 'presentation/screens/teacher/teacher_home_screen.dart';
import 'presentation/screens/teacher/teacher_courses_screen.dart';
import 'presentation/screens/student/student_home_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Student Eval App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: LocalRepository.instance.currentUser == null ? const LoginScreen() : const RoleSelectionScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/roles': (_) => const RoleSelectionScreen(),
          '/teacher/home': (_) => const TeacherHomeScreen(),
          '/teacher/courses': (_) => const TeacherCoursesScreen(),
          '/student/home': (_) => const StudentHomeScreen(),
        },
      ),
    );
  }
}
