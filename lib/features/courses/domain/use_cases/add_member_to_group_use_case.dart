import '../repositories/group_repository.dart';
import '../models/group_model.dart';

class AddMemberToGroupUseCase {
  final CourseGroupRepository repository;
  AddMemberToGroupUseCase(this.repository);

  Future<GroupModel?> call({required String groupId, required String memberName}) {
    if (memberName.trim().isEmpty) throw ArgumentError('Nombre requerido');
    return repository.addMember(groupId: groupId, memberName: memberName.trim());
  }
}
