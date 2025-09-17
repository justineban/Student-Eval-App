import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/course_detail_screen.dart';
import 'package:proyecto_movil/core/entities/course.dart';

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
    appBar: const TopBar(title: 'Ingresar por código'),
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
                final code = _codeCtrl.text.trim();
                Course? courseByCode;
                try {
                  courseByCode = repo.coursesBox.values.firstWhere((c) => c.registrationCode == code);
                } catch (_) {
                  courseByCode = null;
                }
                if (courseByCode != null && courseByCode.teacherId == user.id) {
                  messenger.showSnackBar(const SnackBar(content: Text('Usted es el docente de este curso')));
                  return;
                }
                if (courseByCode != null && courseByCode.studentIds.contains(user.id)) {
                  messenger.showSnackBar(const SnackBar(content: Text('Ya se encuentra inscrito a este curso')));
                  return;
                }
                final course = await repo.enrollByCode(code, user.id);
                messenger.showSnackBar(SnackBar(content: Text(course != null ? 'Inscrito correctamente' : 'Código inválido')));
                if (course != null) {
                  navigator.pushReplacement(MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)));
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
