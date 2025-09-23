import '../models/activity_model.dart';

abstract class ActivityRepository {
  Future<ActivityModel> createActivity({
    required String courseId,
    required String categoryId,
    required String name,
    required String description,
    DateTime? dueDate,
    required bool visible,
  });
  Future<List<ActivityModel>> getActivitiesByCourse(String courseId);
}
