import 'package:uuid/uuid.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_local_datasource.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityLocalDataSource local;
  final _uuid = const Uuid();
  ActivityRepositoryImpl({required this.local});

  @override
  Future<ActivityModel> createActivity({required String courseId, required String categoryId, required String name, required String description, DateTime? dueDate, required bool visible}) async {
    final activity = ActivityModel(
      id: _uuid.v4(),
      courseId: courseId,
      categoryId: categoryId,
      name: name,
      description: description,
      dueDate: dueDate,
      visible: visible,
    );
    return await local.save(activity);
  }

  @override
  Future<List<ActivityModel>> getActivitiesByCourse(String courseId) => local.fetchByCourse(courseId);
}
