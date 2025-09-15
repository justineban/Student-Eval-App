import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/group.dart';
import '../models/adapters.dart';

class LocalRepository extends ChangeNotifier {
  static final LocalRepository instance = LocalRepository._internal();
  LocalRepository._internal();

  static Future<void> registerAdapters() async {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CourseAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GroupAdapter());
  }

  static Future<void> openBoxes() async {
    // Open boxes with defensive recovery in case persisted data is incompatible
    await Hive.openBox<User>('users');
    await Hive.openBox<Course>('courses');
    try {
      await Hive.openBox<Category>('categories');
    } catch (e) {
      // Hive throws RangeError / FormatException when stored binary doesn't match adapter
      // During development we can recover by deleting the corrupted box and recreating it.
      // Note: this clears persisted categories data. For production, implement migrations.
      debugPrint('Failed to open categories box: $e — attempting recovery by deleting box files');
      try {
        await Hive.deleteBoxFromDisk('categories');
      } catch (e2) {
        debugPrint('Failed to delete corrupted categories box: $e2');
      }
      await Hive.openBox<Category>('categories');
    }
    await Hive.openBox<Group>('groups');
    await Hive.openBox('session');
  }

  Box<User> get usersBox => Hive.box<User>('users');
  Box<Course> get coursesBox => Hive.box<Course>('courses');
  Box<Category> get categoriesBox => Hive.box<Category>('categories');
  Box<Group> get groupsBox => Hive.box<Group>('groups');

  User? currentUser;

  Box get sessionBox => Hive.box('session');

  // Load current user from session storage (if any)
  void loadCurrentUserFromSession() {
    final id = sessionBox.get('currentUserId') as String?;
    if (id != null) {
      currentUser = usersBox.get(id);
    }
  }

  Future<User?> register(String email, String password, String name) async {
    // avoid duplicate emails
    final exists = usersBox.values.any((u) => u.email == email);
    if (exists) return null;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = User(id: id, email: email, password: password, name: name);
    await createUser(user);
    // persist session
    sessionBox.put('currentUserId', user.id);
    currentUser = user;
    notifyListeners();
    return user;
  }

  // Persist current user to session
  Future<void> persistSession(User user) async {
    sessionBox.put('currentUserId', user.id);
  }

  Future<User> createUser(User user) async {
    await usersBox.put(user.id, user);
    notifyListeners();
    return user;
  }

  User? login(String email, String password) {
    try {
      final user = usersBox.values.firstWhere((u) => u.email == email && u.password == password);
      currentUser = user;
      sessionBox.put('currentUserId', user.id);
      notifyListeners();
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    sessionBox.delete('currentUserId');
    notifyListeners();
  }

  // Course operations
  Future<Course> createCourse(Course course) async {
    await coursesBox.put(course.id, course);
    notifyListeners();
    return course;
  }

  Course? getCourse(String id) {
    return coursesBox.get(id);
  }

  Future<bool> inviteByEmail(String courseId, String email) async {
    final c = getCourse(courseId);
    if (c == null) return false;
    if (!c.invitations.contains(email)) {
      c.invitations.add(email);
      await coursesBox.put(c.id, c);
      notifyListeners();
    }
    return true;
  }

  // Enroll a user by registration code. Returns the Course if enrollment succeeded, else null.
  Future<Course?> enrollByCode(String code, String userId) async {
    try {
      final course = coursesBox.values.firstWhere((c) => c.registrationCode == code);
      if (!course.studentIds.contains(userId)) {
        course.studentIds.add(userId);
        await coursesBox.put(course.id, course);
        notifyListeners();
      }
      return course;
    } catch (_) {
      return null;
    }
  }

  // Invitation operations for students
  Future<bool> acceptInvitation(String courseId, String userId) async {
    final course = coursesBox.get(courseId);
    if (course == null) return false;
    final user = usersBox.get(userId);
    if (user == null) return false;
    if (!course.invitations.contains(user.email)) return false;
    if (!course.studentIds.contains(userId)) {
      course.studentIds.add(userId);
    }
    course.invitations.remove(user.email);
    await coursesBox.put(course.id, course);
    notifyListeners();
    return true;
  }

  List<Course> listInvitationsForUser(String email) {
    return coursesBox.values.where((c) => c.invitations.contains(email)).toList();
  }

  // Category operations
  Future<Category> createCategory(Category category) async {
    await categoriesBox.put(category.id, category);
    notifyListeners();
    return category;
  }

  Future<Category?> updateCategory(String id, {String? name, bool? randomAssign, int? studentsPerGroup}) async {
    final cat = categoriesBox.get(id);
    if (cat == null) return null;
    if (name != null) cat.name = name;
    if (randomAssign != null) cat.randomAssign = randomAssign;
    if (studentsPerGroup != null) cat.studentsPerGroup = studentsPerGroup;
    await categoriesBox.put(cat.id, cat);
    notifyListeners();
    return cat;
  }

  Future<bool> deleteCategory(String id) async {
    final cat = categoriesBox.get(id);
    if (cat == null) return false;
    // delete associated groups
    final groupsToDelete = groupsBox.values.where((g) => g.categoryId == id).toList();
    for (final g in groupsToDelete) {
      await groupsBox.delete(g.id);
    }
    await categoriesBox.delete(id);
    notifyListeners();
    return true;
  }

  // Create groups for a category based on students in the course
  Future<List<Group>> createGroupsForCategory(String categoryId) async {
    final cat = categoriesBox.get(categoryId);
    if (cat == null) return [];
    final course = coursesBox.get(cat.courseId);
    if (course == null) return [];

    // clear previous groups for this category
    final existing = groupsBox.values.where((g) => g.categoryId == categoryId).toList();
    for (final g in existing) {
      await groupsBox.delete(g.id);
    }

    final students = List<String>.from(course.studentIds);
    final groups = <Group>[];
    if (students.isEmpty) return [];

    if (cat.randomAssign) {
      students.shuffle();
      var idx = 0;
      var groupIndex = 1;
      while (idx < students.length) {
        final members = students.sublist(idx, (idx + cat.studentsPerGroup) > students.length ? students.length : idx + cat.studentsPerGroup);
        final group = Group(id: '${categoryId}_g$groupIndex', categoryId: categoryId, name: 'Grupo $groupIndex', memberIds: List<String>.from(members));
        await groupsBox.put(group.id, group);
        groups.add(group);
        idx += cat.studentsPerGroup;
        groupIndex++;
      }
    } else {
      // self-assigned: create empty groups initially according to studentsPerGroup estimated count
      final groupCount = (students.length / cat.studentsPerGroup).ceil();
      for (var i = 1; i <= groupCount; i++) {
        final group = Group(id: '${categoryId}_g$i', categoryId: categoryId, name: 'Grupo $i', memberIds: []);
        await groupsBox.put(group.id, group);
        groups.add(group);
      }
    }
    notifyListeners();
    return groups;
  }

  List<Group> listGroupsForCategory(String categoryId) {
    return groupsBox.values.where((g) => g.categoryId == categoryId).toList();
  }

  // Student group membership
  Future<bool> joinGroup(String groupId, String userId) async {
    final g = groupsBox.get(groupId);
    if (g == null) return false;
    if (!g.memberIds.contains(userId)) {
      g.memberIds.add(userId);
      await groupsBox.put(g.id, g);
      notifyListeners();
    }
    return true;
  }

  Future<bool> leaveGroup(String groupId, String userId) async {
    final g = groupsBox.get(groupId);
    if (g == null) return false;
    if (g.memberIds.contains(userId)) {
      g.memberIds.remove(userId);
      await groupsBox.put(g.id, g);
      notifyListeners();
    }
    return true;
  }

  List<User> listStudentsForCourse(String courseId) {
    final course = coursesBox.get(courseId);
    if (course == null) return [];
    final users = course.studentIds.map((id) => usersBox.get(id)).whereType<User>().toList();
    return users;
  }
}
