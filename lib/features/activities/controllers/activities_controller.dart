import 'package:flutter/material.dart';
import '../domain/activity_entity.dart';
import '../domain/activity_repository.dart';
import '../domain/use_cases.dart';
import '../data/activity_repository_impl.dart';
import '../domain/assessment_entity.dart';
import '../domain/assessment_use_cases.dart';
import '../domain/assessment_repository.dart';
import '../data/assessment_repository_impl.dart';

/// Controller estilo ChangeNotifier como en Courses para unir UI con casos de uso.
class ActivitiesController with ChangeNotifier {
  final ActivityRepository _repository = ActivityRepositoryImpl();
  final AssessmentRepository _assessmentRepository = AssessmentRepositoryImpl();

  late final CreateActivityUseCase _create;
  late final GetActivityByIdUseCase _getById;
  late final GetActivitiesByCourseUseCase _getByCourse;
  late final GetActivitiesByCategoryUseCase _getByCategory;
  late final UpdateActivityUseCase _update;
  late final DeleteActivityUseCase _delete;
  late final AddSubmissionUseCase _addSubmission;
  late final LaunchAssessmentUseCase _launchAssessment;
  late final GetAssessmentByActivityUseCase _getAssessmentByActivity;
  late final CloseAssessmentUseCase _closeAssessment;

  ActivitiesController() {
    _create = CreateActivityUseCase(_repository);
    _getById = GetActivityByIdUseCase(_repository);
    _getByCourse = GetActivitiesByCourseUseCase(_repository);
    _getByCategory = GetActivitiesByCategoryUseCase(_repository);
    _update = UpdateActivityUseCase(_repository);
    _delete = DeleteActivityUseCase(_repository);
    _addSubmission = AddSubmissionUseCase(_repository);
    _launchAssessment = LaunchAssessmentUseCase(_assessmentRepository);
    _getAssessmentByActivity = GetAssessmentByActivityUseCase(
      _assessmentRepository,
    );
    _closeAssessment = CloseAssessmentUseCase(_assessmentRepository);
  }

  bool _loading = false;
  String? _error;
  List<Activity> _cacheCourse = [];
  List<Activity> _cacheCategory = [];
  final Map<String, Assessment?> _assessmentCache =
      {}; // activityId -> assessment

  bool get loading => _loading;
  String? get error => _error;
  List<Activity> get courseActivities => List.unmodifiable(_cacheCourse);
  List<Activity> get categoryActivities => List.unmodifiable(_cacheCategory);
  Assessment? assessmentFor(String activityId) => _assessmentCache[activityId];

  /// Obtiene actividades de una categoría sin tocar el caché global.
  Future<List<Activity>> fetchActivitiesForCategory(String categoryId) async {
    return _getByCategory(categoryId);
  }

  Future<Activity?> createActivity({
    required String courseId,
    required String categoryId,
    required String title,
    required String description,
    DateTime? dueDate,
    int maxScore = 100,
  }) async {
    _setLoading(true);
    try {
      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId,
        categoryId: categoryId,
        title: title,
        description: description,
        dueDate: dueDate,
        maxScore: maxScore,
      );
      final created = await _create(activity);
      _setLoading(false);
      return created;
    } catch (e) {
      return _setError(e);
    }
  }

  Future<void> loadByCourse(String courseId) async {
    _setLoading(true);
    try {
      _cacheCourse = await _getByCourse(courseId);
      _setLoading(false);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> loadByCategory(String categoryId) async {
    _setLoading(true);
    try {
      _cacheCategory = await _getByCategory(categoryId);
      _setLoading(false);
    } catch (e) {
      _setError(e);
    }
  }

  Future<bool> updateActivity(Activity activity) async {
    _setLoading(true);
    try {
      final ok = await _update(activity);
      _setLoading(false);
      return ok;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> deleteActivity(String id) async {
    _setLoading(true);
    try {
      final ok = await _delete(id);
      _setLoading(false);
      return ok;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> changeActivityCategory(
    Activity activity,
    String newCategoryId,
  ) async {
    _setLoading(true);
    try {
      activity.categoryId = newCategoryId;
      final ok = await _update(activity);
      _setLoading(false);
      return ok;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<bool> addSubmission(String activityId, String studentId) async {
    _setLoading(true);
    try {
      final ok = await _addSubmission(
        activityId: activityId,
        studentId: studentId,
      );
      _setLoading(false);
      return ok;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Future<Activity?> getById(String id) => _getById(id);

  // Assessment operations
  Future<Assessment?> launchAssessment(String activityId) async {
    _setLoading(true);
    try {
      final a = await _launchAssessment(activityId);
      _assessmentCache[activityId] = a;
      _setLoading(false);
      return a;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<Assessment?> loadAssessment(String activityId) async {
    _setLoading(true);
    try {
      final a = await _getAssessmentByActivity(activityId);
      _assessmentCache[activityId] = a;
      _setLoading(false);
      return a;
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<bool> closeAssessment(String activityId) async {
    _setLoading(true);
    try {
      final ok = await _closeAssessment(activityId);
      if (ok) {
        final a = _assessmentCache[activityId];
        if (a != null) a.closed = true;
      }
      _setLoading(false);
      return ok;
    } catch (e) {
      _setError(e);
      return false;
    }
  }

  Activity? _setError(Object e) {
    _loading = false;
    _error = e.toString();
    notifyListeners();
    return null;
  }

  void _setLoading(bool value) {
    _loading = value;
    if (value) _error = null;
    notifyListeners();
  }
}
