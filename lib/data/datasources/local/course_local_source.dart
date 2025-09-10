class CourseLocalSource {
  final Map<String, List<Map<String, dynamic>>> _userCourses = {};

  Future<List<Map<String, dynamic>>> getCoursesForUser(String userId) async {
    return _userCourses[userId] ?? [];
  }

  Future<bool> saveCourse(
    String userId,
    Map<String, dynamic> courseData,
  ) async {
    _userCourses.putIfAbsent(userId, () => []).add(courseData);
    return true;
  }
}
