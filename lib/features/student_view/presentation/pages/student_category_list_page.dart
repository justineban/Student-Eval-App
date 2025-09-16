import 'package:flutter/material.dart';
import 'package:proyecto_movil/features/teacher_view/data/category_service.dart';
import 'package:proyecto_movil/features/teacher_view/domain/entities/category.dart';
import 'package:proyecto_movil/features/student_view/presentation/pages/student_group_list_page.dart';

class StudentCategoryListPage extends StatelessWidget {
  final String courseId;
  const StudentCategoryListPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final categoryService = CategoryService();
    final List<Category> categories = categoryService.getCategoriesForCourse(courseId);
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            title: Text(category.name),
            subtitle: Text('Máx. estudiantes por grupo: ${category.studentsPerGroup}'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => StudentGroupListPage(categoryId: category.id)));
              },
              child: const Text('Ver Grupos'),
            ),
          );
        },
      ),
    );
  }
}
