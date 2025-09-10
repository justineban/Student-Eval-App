import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/course_repository_impl.dart';
import 'user_courses_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = AuthRepositoryImpl().users;
    final role = AuthRepositoryImpl().currentRole;

    if (role != 'teacher') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Solo los profesores pueden ver la lista completa de usuarios',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final enrolledCount = CourseRepositoryImpl().countCoursesForUser(
            user.id,
          );
          return ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Text('$enrolledCount cursos'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserCoursesScreen(userId: user.id, userName: user.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
