import '../repositories/group_repository.dart';
import '../models/group_model.dart';

class RemoveMemberFromGroupUseCase {
  final CourseGroupRepository repository;
  RemoveMemberFromGroupUseCase(this.repository);

  Future<GroupModel?> call({required String groupId, required String memberName}) {
    return repository.removeMember(groupId: groupId, memberName: memberName);
  }
}
