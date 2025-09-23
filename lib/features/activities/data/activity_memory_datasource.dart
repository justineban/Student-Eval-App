import '../domain/activity_entity.dart';

/// In-memory datasource similar al CourseService usado en otros features.
class ActivityMemoryDataSource {
  static final ActivityMemoryDataSource _instance =
      ActivityMemoryDataSource._internal();
  factory ActivityMemoryDataSource() => _instance;
  ActivityMemoryDataSource._internal();

  final Map<String, Activity> _activities = {}; // id -> Activity

  Activity create(Activity activity) {
    _activities[activity.id] = activity;
    return activity;
  }

  Activity? getById(String id) => _activities[id];

  List<Activity> getByCourse(String courseId) =>
      _activities.values.where((a) => a.courseId == courseId).toList();

  List<Activity> getByCategory(String categoryId) =>
      _activities.values.where((a) => a.categoryId == categoryId).toList();

  bool update(Activity activity) {
    if (!_activities.containsKey(activity.id)) return false;
    _activities[activity.id] = activity;
    return true;
  }

  bool delete(String id) => _activities.remove(id) != null;

  bool addSubmission({required String activityId, required String studentId}) {
    final activity = _activities[activityId];
    if (activity == null) return false;
    if (!activity.submissions.contains(studentId)) {
      activity.submissions.add(studentId);
    }
    return true;
  }
}
