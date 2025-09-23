// Add course page (inputs & button enabled, no persistence logic)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../ui/controllers/course_controller.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});
  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseController = Get.find<CourseController>();
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Curso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (courseController.error.value != null)
                  Text(courseController.error.value!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del curso'),
                ),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: courseController.loading.value
                      ? null
                      : () async {
                          final teacherId = auth.currentUser.value?.id;
                          if (teacherId == null) return;
                          final created = await courseController.createCourse(
                            name: _nameCtrl.text.trim(),
                            description: _descCtrl.text.trim(),
                            teacherId: teacherId,
                          );
                          if (created != null) {
                            Get.back(result: created);
                          }
                        },
                  child: courseController.loading.value
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar Curso'),
                ),
                const SizedBox(height: 12),
                const Text('Crear curso (persistencia en memoria por ahora).',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )),
      ),
    );
  }
}
