import 'package:flutter/material.dart';
import '../../../data/repositories/course_repository_impl.dart';
import '../../../data/repositories/auth_repository_impl.dart';

class JoinCourseScreen extends StatefulWidget {
  const JoinCourseScreen({super.key});

  @override
  State<JoinCourseScreen> createState() => _JoinCourseScreenState();
}

class _JoinCourseScreenState extends State<JoinCourseScreen> {
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse a un Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código de registro',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _join, child: const Text('Unirse')),
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final current = AuthRepositoryImpl().currentUser;
    if (current == null) return;
    final success = await CourseRepositoryImpl().enrollByCode(code, current.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Te uniste al curso')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Código inválido')));
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
