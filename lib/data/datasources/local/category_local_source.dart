class CategoryLocalSource {
  final Map<String, List<Map<String, dynamic>>> _courseCategories = {};
  final Map<String, List<Map<String, dynamic>>> _categoryGroups = {};

  Future<List<Map<String, dynamic>>> getCategoriesForCourse(
    String courseId,
  ) async {
    return _courseCategories[courseId] ?? [];
  }

  Future<List<Map<String, dynamic>>> getGroupsForCategory(
    String categoryId,
  ) async {
    return _categoryGroups[categoryId] ?? [];
  }

  Future<bool> saveCategory(
    String courseId,
    Map<String, dynamic> categoryData,
  ) async {
    _courseCategories.putIfAbsent(courseId, () => []).add(categoryData);
    return true;
  }

  Future<bool> saveGroup(
    String categoryId,
    Map<String, dynamic> groupData,
  ) async {
    _categoryGroups.putIfAbsent(categoryId, () => []).add(groupData);
    return true;
  }
}
