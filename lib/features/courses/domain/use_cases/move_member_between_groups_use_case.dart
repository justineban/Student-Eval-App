import '../repositories/group_repository.dart';
import '../models/group_model.dart';

class MoveMemberBetweenGroupsUseCase {
  final CourseGroupRepository repository;
  MoveMemberBetweenGroupsUseCase(this.repository);

  Future<(GroupModel from, GroupModel to)?> call({
    required String fromGroupId,
    required String toGroupId,
    required String memberName,
  }) {
    return repository.moveMember(fromGroupId: fromGroupId, toGroupId: toGroupId, memberName: memberName);
  }
}
