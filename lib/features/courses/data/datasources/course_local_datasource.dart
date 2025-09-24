import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/course_model.dart';

abstract class CourseLocalDataSource {
  Future<CourseModel> saveCourse(CourseModel course);
  Future<List<CourseModel>> fetchCoursesByTeacher(String teacherId);
  Future<CourseModel?> fetchCourseById(String id);
  Future<CourseModel> updateCourse(CourseModel course);
  Future<void> deleteCourse(String id);
}

class InMemoryCourseLocalDataSource implements CourseLocalDataSource {
  final List<CourseModel> _courses = [];

  @override
  Future<CourseModel> saveCourse(CourseModel course) async {
    _courses.add(course);
    return course;
  }

  @override
  Future<List<CourseModel>> fetchCoursesByTeacher(String teacherId) async {
    return _courses.where((c) => c.teacherId == teacherId).toList();
  }

  @override
  Future<CourseModel?> fetchCourseById(String id) async {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CourseModel> updateCourse(CourseModel course) async {
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = course;
    }
    return course;
  }

  @override
  Future<void> deleteCourse(String id) async {
    _courses.removeWhere((c) => c.id == id);
  }
}

class HiveCourseLocalDataSource implements CourseLocalDataSource {
  late final Box _coursesBox; // stores course maps keyed by course id
  late final Box _teacherIndexBox; // maps teacherId -> List<String> courseIds

  HiveCourseLocalDataSource({Box? coursesBox, Box? teacherIndexBox}) {
    _coursesBox = coursesBox ?? Hive.box(HiveBoxes.courses);
    _teacherIndexBox = teacherIndexBox ?? Hive.box(HiveBoxes.teacherCourses);
  }

  @override
  Future<CourseModel> saveCourse(CourseModel course) async {
    await _coursesBox.put(course.id, _toMap(course));
    final key = course.teacherId;
    final existing = (_teacherIndexBox.get(key) as List?)?.cast<String>() ?? <String>[];
    if (!existing.contains(course.id)) {
      existing.add(course.id);
      await _teacherIndexBox.put(key, existing);
    }
    return course;
  }

  @override
  Future<List<CourseModel>> fetchCoursesByTeacher(String teacherId) async {
    final ids = (_teacherIndexBox.get(teacherId) as List?)?.cast<String>() ?? const <String>[];
    final List<CourseModel> result = [];
    for (final id in ids) {
      final data = _coursesBox.get(id);
      if (data is Map) {
        result.add(_fromMap(data));
      }
    }
    return result;
  }

  @override
  Future<CourseModel?> fetchCourseById(String id) async {
    final data = _coursesBox.get(id);
    if (data is Map) return _fromMap(data);
    return null;
  }

  @override
  Future<CourseModel> updateCourse(CourseModel course) async {
    await _coursesBox.put(course.id, _toMap(course));
    return course;
  }

  @override
  Future<void> deleteCourse(String id) async {
    // Get full course record first (for teacherId and cascade deletes)
    final data = _coursesBox.get(id);
    String? teacherId;
    if (data is Map && data['teacherId'] is String) {
      teacherId = data['teacherId'] as String;
    }

    // Cascade delete: categories, activities, and groups that belong to this course
    try {
      // Categories
      final categoriesBox = Hive.box(HiveBoxes.categories);
      final List<dynamic> catKeys = categoriesBox.keys.toList(growable: false);
      final toDeleteCategories = <dynamic>[];
      for (final key in catKeys) {
        final c = categoriesBox.get(key);
        if (c is Map && c['courseId'] == id) {
          toDeleteCategories.add(key);
        }
      }
      if (toDeleteCategories.isNotEmpty) {
        await categoriesBox.deleteAll(toDeleteCategories);
      }

      // Activities
      final activitiesBox = Hive.box(HiveBoxes.activities);
      final List<dynamic> actKeys = activitiesBox.keys.toList(growable: false);
      final toDeleteActivities = <dynamic>[];
      for (final key in actKeys) {
        final a = activitiesBox.get(key);
        if (a is Map && a['courseId'] == id) {
          toDeleteActivities.add(key);
        }
      }
      if (toDeleteActivities.isNotEmpty) {
        await activitiesBox.deleteAll(toDeleteActivities);
      }

      // Groups (stored with both courseId and categoryId)
      final groupsBox = Hive.box(HiveBoxes.groups);
      final List<dynamic> groupKeys = groupsBox.keys.toList(growable: false);
      final toDeleteGroups = <dynamic>[];
      for (final key in groupKeys) {
        final g = groupsBox.get(key);
        if (g is Map && g['courseId'] == id) {
          toDeleteGroups.add(key);
        }
      }
      if (toDeleteGroups.isNotEmpty) {
        await groupsBox.deleteAll(toDeleteGroups);
      }
    } catch (_) {
      // Swallow cascade errors to ensure main course delete proceeds; caller will handle any higher-level errors
    }

    // Delete course itself
    await _coursesBox.delete(id);

    // Clean teacher -> course index
    if (teacherId != null) {
      final key = teacherId;
      final existing = (_teacherIndexBox.get(key) as List?)?.cast<String>() ?? <String>[];
      if (existing.contains(id)) {
        existing.remove(id);
        await _teacherIndexBox.put(key, existing);
      }
    }
  }

  Map<String, dynamic> _toMap(CourseModel c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'teacherId': c.teacherId,
        'registrationCode': c.registrationCode,
        'studentIds': c.studentIds,
        'invitations': c.invitations,
      };

  CourseModel _fromMap(Map map) => CourseModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        teacherId: map['teacherId'] as String,
        registrationCode: map['registrationCode'] as String,
        studentIds: (map['studentIds'] as List?)?.cast<String>(),
        invitations: (map['invitations'] as List?)?.cast<String>(),
      );
}

// Remote datasource placeholder for future API integration
abstract class CourseRemoteDataSource {
  Future<CourseModel> createRemoteCourse({required String name, required String description, required String teacherId});
  Future<List<CourseModel>> fetchRemoteCoursesByTeacher(String teacherId);
}

class StubCourseRemoteDataSource implements CourseRemoteDataSource {
  @override
  Future<CourseModel> createRemoteCourse({required String name, required String description, required String teacherId}) async {
    // TODO: implement API call
    throw UnimplementedError('Remote createCourse not implemented');
  }

  @override
  Future<List<CourseModel>> fetchRemoteCoursesByTeacher(String teacherId) async {
    // TODO: implement API call
    return [];
  }
}
