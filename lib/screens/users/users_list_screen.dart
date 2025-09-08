import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import 'user_courses_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = AuthService().users;
    final role = AuthService().currentRole;

    if (role != 'teacher') {
      return const Scaffold(body: Center(child: Text('Solo los profesores pueden ver la lista completa de usuarios')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final enrolledCount = CourseService().countCoursesForUser(user.id);
          return ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Text('$enrolledCount cursos'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserCoursesScreen(userId: user.id, userName: user.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
