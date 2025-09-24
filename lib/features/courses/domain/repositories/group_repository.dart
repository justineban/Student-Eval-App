import '../models/group_model.dart';

abstract class CourseGroupRepository {
  Future<GroupModel> create({required String courseId, required String categoryId, required String name});
  Future<List<GroupModel>> listByCategory(String categoryId);
  Future<void> delete(String id);
  Future<GroupModel?> addMember({required String groupId, required String memberName});
  Future<GroupModel?> removeMember({required String groupId, required String memberName});
  Future<(GroupModel from, GroupModel to)?> moveMember({
    required String fromGroupId,
    required String toGroupId,
    required String memberName,
  });
  // Ensure all groups in a category do not exceed the given capacity; returns affected group IDs
  Future<List<GroupModel>> trimGroupsToCapacity({required String categoryId, required int maxPerGroup});
}
