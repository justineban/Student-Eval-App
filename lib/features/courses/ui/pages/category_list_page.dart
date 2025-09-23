import 'package:flutter/material.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: const Center(child: Text('Aún no hay categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: abrir creación de categoría (use case futuro)
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
