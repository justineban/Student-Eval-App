import 'package:flutter/material.dart';
import '../data/category_service.dart';
import '../../../core/entities/category.dart';

class CategoryController with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  List<Category> getCategoriesForCourse(String courseId) {
    return _categoryService.getCategoriesForCourse(courseId);
  }

  Category? getCategory(String courseId, String categoryId) {
    return _categoryService.getCategory(courseId, categoryId);
  }

  Future<Category?> addCategory(String courseId, String name, bool randomAssign, int studentsPerGroup) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final category = await _categoryService.addCategory(courseId, name, randomAssign, studentsPerGroup);
      _loading = false;
      notifyListeners();
      return category;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  bool updateCategory(String courseId, Category updatedCategory) {
    final result = _categoryService.updateCategory(courseId, updatedCategory);
    notifyListeners();
    return result;
  }

  bool deleteCategory(String courseId, String categoryId) {
    final result = _categoryService.deleteCategory(courseId, categoryId);
    notifyListeners();
    return result;
  }
}
