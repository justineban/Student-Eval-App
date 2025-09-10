import '../../domain/models/category.dart';

abstract class CategoryRepository {
  List<Category> getCategoriesForCourse(String courseId);
  Category? getCategory(String courseId, String categoryId);
  Future<Category> addCategory(
    String courseId,
    String name,
    String groupingMethod,
    int maxStudentsPerGroup,
  );
  List<Group> getGroupsForCategory(String categoryId);
  List<Group> getAllGroups();
  Group? getGroup(String categoryId, String groupId);
  int addMemberToGroup(String categoryId, String groupId, String userId);
  Category? getCategoryById(String categoryId);
  bool removeMemberFromGroup(String categoryId, String groupId, String userId);
  bool updateCategory(String courseId, Category updatedCategory);
  bool deleteCategory(String courseId, String categoryId);
}
