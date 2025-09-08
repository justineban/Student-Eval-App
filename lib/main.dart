import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/courses/course_list_screen.dart';
import 'screens/courses/enrolled_courses_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/users/users_list_screen.dart';
import 'screens/category/category_picker_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/category/all_groups_screen.dart';
import 'screens/courses/join_course_screen.dart';
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
            : const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
  '/select-course-for-categories': (context) => const CategoryPickerScreen(),
  '/select-role': (context) => const RoleSelectionScreen(),
  '/all-groups': (context) => const AllGroupsScreen(),
  '/join-course': (context) => const JoinCourseScreen(),
        '/courses': (context) => const CourseListScreen(),
        '/enrolled': (context) => const EnrolledCoursesScreen(), // Ruta añadida
        '/users': (context) => const UsersListScreen(),
      },
    );
  }
}
