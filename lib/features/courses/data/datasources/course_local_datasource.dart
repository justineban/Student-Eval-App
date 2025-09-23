import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/models/course_model.dart';

abstract class CourseLocalDataSource {
  Future<CourseModel> saveCourse(CourseModel course);
  Future<List<CourseModel>> fetchCoursesByTeacher(String teacherId);
  Future<CourseModel?> fetchCourseById(String id);
  Future<CourseModel> updateCourse(CourseModel course);
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
