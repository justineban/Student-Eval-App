import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/courses/course_list_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cursos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthService().currentUser == null
            ? const LoginScreen()
            : const CourseListScreen(),
        '/login': (context) => const LoginScreen(),
        '/courses': (context) => const CourseListScreen(),
      },
    );
  }
}
