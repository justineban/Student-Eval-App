import 'package:flutter/material.dart';
import '../../../data/repositories/course_repository_impl.dart';
import 'category_list_screen.dart';

class CategoryPickerScreen extends StatelessWidget {
  const CategoryPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = CourseRepositoryImpl().courses;

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Curso')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Select Curse', style: TextStyle(fontSize: 20)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return ListTile(
                  title: Text(course.name),
                  subtitle: Text(course.description),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryListScreen(courseId: course.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
