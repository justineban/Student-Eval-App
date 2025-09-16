import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/features/core/data/local/local_repository.dart';
import 'package:proyecto_movil/features/student_view/presentation/pages/student_course_detail_page.dart';

class JoinCoursePage extends StatefulWidget {
  const JoinCoursePage({super.key});

  @override
  State<JoinCoursePage> createState() => _JoinCoursePageState();
}

class _JoinCoursePageState extends State<JoinCoursePage> {
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscribirse por código')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Course Code'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async {
              final repo = Provider.of<LocalRepository>(context, listen: false);
              final user = repo.currentUser;
              if (user == null) return;
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final code = _codeController.text.trim();
              if (code.isEmpty) return;
              final course = await repo.enrollByCode(code, user.id);
              if (!mounted) return;
              if (course != null) {
                nav.pushReplacement(MaterialPageRoute(builder: (_) => StudentCourseDetailScreen(courseId: course.id)));
              } else {
                messenger.showSnackBar(const SnackBar(content: Text('Código inválido')));
              }
            }, child: const Text('Inscribirse')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
