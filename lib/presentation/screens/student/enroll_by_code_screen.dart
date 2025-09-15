import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';
import '../../widgets/top_bar.dart';
import 'student_course_view.dart';

class EnrollByCodeScreen extends StatefulWidget {
  const EnrollByCodeScreen({super.key});

  @override
  State<EnrollByCodeScreen> createState() => _EnrollByCodeScreenState();
}

class _EnrollByCodeScreenState extends State<EnrollByCodeScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    return Scaffold(
      appBar: TopBar(roleName: 'Estudiante', title: 'Ingresar por código'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Código de inscripción')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (user == null) return;
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final course = await repo.enrollByCode(_codeCtrl.text.trim(), user.id);
                messenger.showSnackBar(SnackBar(content: Text(course != null ? 'Inscrito correctamente' : 'Código inválido')));
                if (course != null) {
                  navigator.pushReplacement(MaterialPageRoute(builder: (_) => StudentCourseView(courseId: course.id)));
                }
              },
              child: const Text('Ingresar'),
            )
          ],
        ),
      ),
    );
  }
}
