import 'package:flutter/material.dart';
import 'presentation/pages/auth/login_screen.dart';
import 'presentation/pages/courses/course_list_screen.dart';
import 'presentation/pages/courses/enrolled_courses_screen.dart';
import 'presentation/pages/home/home_screen.dart';
import 'presentation/pages/users/users_list_screen.dart';
import 'presentation/pages/category/category_picker_screen.dart';
import 'presentation/pages/auth/role_selection_screen.dart';
import 'presentation/pages/category/all_groups_screen.dart';
import 'presentation/pages/courses/join_course_screen.dart';
import 'data/repositories/auth_repository_impl.dart';

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
        '/': (context) => AuthRepositoryImpl().currentUser == null
            ? const LoginScreen()
            : const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/select-course-for-categories': (context) =>
            const CategoryPickerScreen(),
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
