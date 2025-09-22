import '../entities/group.dart';
import '../repositories/group_repository.dart';

class LeaveGroupUseCase {
  final GroupRepository groupRepository;
  LeaveGroupUseCase(this.groupRepository);

  Future<GroupEntity?> call({required String groupId, required String userId}) async {
    final group = await groupRepository.getById(groupId);
    if (group == null) return null;
    if (group.memberIds.contains(userId)) {
      final updated = group.copyWith(memberIds: List<String>.from(group.memberIds)..remove(userId));
      await groupRepository.save(updated);
      return updated;
    }
    return group;
  }
}
