import 'package:uuid/uuid.dart';
import '../../domain/models/group_model.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_local_datasource.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupLocalDataSource local;
  final _uuid = const Uuid();
  GroupRepositoryImpl({required this.local});

  @override
  Future<GroupModel> createGroup({required String courseId, required String categoryId, required String name}) async {
    final group = GroupModel(id: _uuid.v4(), categoryId: categoryId, courseId: courseId, name: name);
    return await local.save(group);
  }

  @override
  Future<List<GroupModel>> getGroupsByCategory(String categoryId) => local.fetchByCategory(categoryId);

  @override
  Future<void> deleteGroup(String id) => local.delete(id);
}
