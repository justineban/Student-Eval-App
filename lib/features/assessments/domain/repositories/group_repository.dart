import '../models/group_model.dart';

abstract class GroupRepository {
  Future<GroupModel> createGroup({required String courseId, required String categoryId, required String name});
  Future<List<GroupModel>> getGroupsByCategory(String categoryId);
  Future<void> deleteGroup(String id);
}
