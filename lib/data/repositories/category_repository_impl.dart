import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  static final CategoryRepositoryImpl _instance =
      CategoryRepositoryImpl._internal();
  factory CategoryRepositoryImpl() => _instance;
  CategoryRepositoryImpl._internal();

  final Map<String, List<Category>> _courseCategories = {};
  // groups keyed by categoryId
  final Map<String, List<Group>> _categoryGroups = {};

  List<Category> getCategoriesForCourse(String courseId) {
    return _courseCategories[courseId] ?? [];
  }

  Category? getCategory(String courseId, String categoryId) {
    final categories = _courseCategories[courseId] ?? [];
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  Future<Category> addCategory(
    String courseId,
    String name,
    String groupingMethod,
    int maxStudentsPerGroup,
  ) async {
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      name: name,
      groupingMethod: groupingMethod,
      maxStudentsPerGroup: maxStudentsPerGroup,
    );

    _courseCategories[courseId] ??= [];
    _courseCategories[courseId]!.add(category);
    // create initial groups. Assumption: create a number of groups equal to maxStudentsPerGroup
    final groups = <Group>[];
    final count = maxStudentsPerGroup > 0 ? maxStudentsPerGroup : 1;
    for (var i = 0; i < count; i++) {
      groups.add(
        Group(
          id: '${category.id}-g-$i',
          categoryId: category.id,
          name: 'Group ${i + 1}',
        ),
      );
    }
    _categoryGroups[category.id] = groups;
    return category;
  }

  List<Group> getGroupsForCategory(String categoryId) {
    return _categoryGroups[categoryId] ?? [];
  }

  List<Group> getAllGroups() {
    final all = <Group>[];
    for (var list in _categoryGroups.values) {
      all.addAll(list);
    }
    return all;
  }

  Group? getGroup(String categoryId, String groupId) {
    final groups = _categoryGroups[categoryId] ?? [];
    try {
      return groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Add a member to a group.
  /// Returns: 1 = success, 2 = already member, 3 = group full, 0 = failure (group not found)
  int addMemberToGroup(String categoryId, String groupId, String userId) {
    final group = getGroup(categoryId, groupId);
    if (group == null) return 0;

    // find category to get maxStudentsPerGroup
    final category = getCategoryById(categoryId);
    final capacity = category?.maxStudentsPerGroup ?? 0;

    if (group.memberUserIds.contains(userId)) return 2;
    if (capacity > 0 && group.memberUserIds.length >= capacity) return 3;

    group.memberUserIds.add(userId);
    return 1;
  }

  Category? getCategoryById(String categoryId) {
    for (var entries in _courseCategories.values) {
      for (var cat in entries) {
        if (cat.id == categoryId) return cat;
      }
    }
    return null;
  }

  bool removeMemberFromGroup(String categoryId, String groupId, String userId) {
    final group = getGroup(categoryId, groupId);
    if (group == null) return false;
    final initial = group.memberUserIds.length;
    group.memberUserIds.removeWhere((id) => id == userId);
    return group.memberUserIds.length < initial;
  }

  bool updateCategory(String courseId, Category updatedCategory) {
    final categories = _courseCategories[courseId];
    if (categories == null) return false;

    final index = categories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index == -1) return false;

    categories[index] = updatedCategory;
    return true;
  }

  bool deleteCategory(String courseId, String categoryId) {
    final categories = _courseCategories[courseId];
    if (categories == null) return false;

    final initialLength = categories.length;
    categories.removeWhere((cat) => cat.id == categoryId);
    return categories.length < initialLength;
  }
}
