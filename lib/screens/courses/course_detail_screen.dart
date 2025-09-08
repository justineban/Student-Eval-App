import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../category/category_list_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final course = CourseService().getCourse(widget.courseId);

    if (course == null) {
      return const Scaffold(body: Center(child: Text('Curso no encontrado')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(course.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción:', style: Theme.of(context).textTheme.titleLarge),
            Text(course.description),
            const SizedBox(height: 8),
            Text('Profesor: ${course.ownerName}'),
            const SizedBox(height: 4),
            if (AuthService().currentRole == 'teacher') Text('Código de registro: ${course.registrationCode}'),
            const SizedBox(height: 20),
            Text(
              'Usuarios Inscritos:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: course.enrolledUserIds.length,
                itemBuilder: (context, index) {
                  final userId = course.enrolledUserIds[index];
                  String display = userId;
                  try {
                    final user = AuthService().users.firstWhere((u) => u.id == userId);
                    display = user.name;
                  } catch (e) {
                    // keep id as fallback
                  }
                  return ListTile(
                    title: Text(display),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Agregar usuario por email',
                hintText: 'usuario@dominio.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addUserByEmail,
                  child: const Text('Agregar Usuario'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryListScreen(courseId: widget.courseId),
                      ),
                    );
                  },
                  child: const Text('Gestionar Categorías'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: AuthService().currentRole == 'student'
          ? FloatingActionButton(
              onPressed: () async {
                final currentUser = AuthService().currentUser;
                if (currentUser != null) {
                  await CourseService().enrollUser(course.id, currentUser.id);
                  setState(() {});
                }
              },
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Future<void> _addUserByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    // find user by email
    final users = AuthService().users;
    try {
      final user = users.firstWhere((u) => u.email == email);
      final current = AuthService().currentUser;
      final course = CourseService().getCourse(widget.courseId);
      if (current == null || course == null) return;

      // Only the teacher owner can add other users
      if (AuthService().currentRole != 'teacher' || course.ownerId != current.id) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo el profesor propietario puede agregar usuarios')));
        return;
      }

      final success = await CourseService().enrollUser(widget.courseId, user.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario agregado al curso')));
          setState(() {});
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo agregar el usuario')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
    }
    _emailController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
