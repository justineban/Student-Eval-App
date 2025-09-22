import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_movil/core/widgets/top_bar.dart';
import 'package:proyecto_movil/features/courses/presentation/course_detail_screen.dart';
import 'package:proyecto_movil/core/entities/course.dart' as legacy;
import 'controllers/student_courses_controller.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

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
  final controller = Get.find<StudentCoursesController>();
  final auth = Get.find<AuthController>();
  final userId = auth.currentUserId.value;
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
                if (userId == null) return;
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final code = _codeCtrl.text.trim();
                final courseEntity = await controller.enroll(code);
                messenger.showSnackBar(SnackBar(content: Text(courseEntity != null ? 'Inscrito correctamente' : 'Código inválido')));
                if (courseEntity != null) {
                  final legacyCourse = legacy.Course(
                    id: courseEntity.id,
                    name: courseEntity.name,
                    description: courseEntity.description,
                    teacherId: courseEntity.teacherId,
                    registrationCode: courseEntity.registrationCode,
                    studentIds: courseEntity.studentIds,
                    invitations: courseEntity.invitations,
                  );
                  navigator.pushReplacement(MaterialPageRoute(builder: (_) => CourseDetailScreen(course: legacyCourse)));
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
