import '../entities/group.dart';
import '../repositories/group_repository.dart';

class JoinGroupUseCase {
  final GroupRepository groupRepository;
  JoinGroupUseCase(this.groupRepository);

  Future<GroupEntity?> call({required String groupId, required String userId, int? capacity}) async {
    final group = await groupRepository.getById(groupId);
    if (group == null) return null;
    if (capacity != null && group.memberIds.length >= capacity) return null;
    if (!group.memberIds.contains(userId)) {
      final updated = group.copyWith(memberIds: List<String>.from(group.memberIds)..add(userId));
      await groupRepository.save(updated);
      return updated;
    }
    return group;
  }
}
