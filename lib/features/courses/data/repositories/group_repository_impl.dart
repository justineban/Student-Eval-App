import 'package:uuid/uuid.dart';
import '../../domain/models/group_model.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_local_datasource.dart';

class CourseGroupRepositoryImpl implements CourseGroupRepository {
  final CourseGroupLocalDataSource local;
  final _uuid = const Uuid();
  CourseGroupRepositoryImpl({required this.local});

  @override
  Future<GroupModel> create({required String courseId, required String categoryId, required String name}) async {
    final g = GroupModel(id: _uuid.v4(), courseId: courseId, categoryId: categoryId, name: name);
    return await local.save(g);
  }

  @override
  Future<List<GroupModel>> listByCategory(String categoryId) => local.fetchByCategory(categoryId);
  
  @override
  Future<GroupModel?> addMember({required String groupId, required String memberName}) async {
    final existing = await local.fetchById(groupId);
    if (existing == null) return null;
    final updated = GroupModel(
      id: existing.id,
      courseId: existing.courseId,
      categoryId: existing.categoryId,
      name: existing.name,
      memberIds: [...existing.memberIds, memberName],
    );
    await local.save(updated);
    return updated;
  }

  @override
  Future<void> delete(String id) => local.delete(id);
}
