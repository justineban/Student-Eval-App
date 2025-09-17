import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../entities/user.dart';
import '../entities/course.dart';
import '../entities/category.dart';
import '../entities/group.dart';
import '../entities/adapters.dart';

class LocalRepository extends ChangeNotifier {
  // Getter público para obtener todos los usuarios
  List<User> get users => usersBox.values.toList();

  Future<void> moveStudentToGroup({required String userId, required String fromGroupId, required String toGroupId}) async {
    final fromGroup = groupsBox.get(fromGroupId);
    final toGroup = groupsBox.get(toGroupId);
    if (fromGroup == null || toGroup == null) return;
    if (fromGroup.memberIds.contains(userId)) {
      fromGroup.memberIds.remove(userId);
      await groupsBox.put(fromGroup.id, fromGroup);
    }
    if (!toGroup.memberIds.contains(userId)) {
      toGroup.memberIds.add(userId);
      await groupsBox.put(toGroup.id, toGroup);
    }
    notifyListeners();
  }
  Future<void> deleteGroup(String groupId) async {
    await groupsBox.delete(groupId);
    notifyListeners();
  }
  static final LocalRepository instance = LocalRepository._internal();
  LocalRepository._internal();

  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CourseAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GroupAdapter());
  }

  static Future<void> openBoxes() async {
    await Hive.openBox<User>('users');
    await Hive.openBox<Course>('courses');
    try {
      await Hive.openBox<Category>('categories');
    } catch (e) {
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

  void loadCurrentUserFromSession() {
    final id = sessionBox.get('currentUserId') as String?;
    if (id != null) {
      currentUser = usersBox.get(id);
    }
  }

  Future<User?> register(String email, String password, String name) async {
    final exists = usersBox.values.any((u) => u.email == email);
    if (exists) return null;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = User(id: id, email: email, password: password, name: name);
    await createUser(user);
    sessionBox.put('currentUserId', user.id);
    currentUser = user;
    notifyListeners();
    return user;
  }

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

  Future<Course?> enrollByCode(String code, String userId) async {
    try {
      final course = coursesBox.values.firstWhere((c) => c.registrationCode == code);
      // Validación: el docente no puede inscribirse a su propio curso
      if (course.teacherId == userId) {
        return null;
      }
      if (!course.studentIds.contains(userId)) {
        course.studentIds.add(userId);
        await coursesBox.put(course.id, course);
        // Regenerar grupos de todas las categorías de este curso
        for (final cat in categoriesBox.values.where((c) => c.courseId == course.id)) {
          await createGroupsForCategory(cat.id, onlyAssignNew: true, newStudentId: userId);
        }
        notifyListeners();
      }
      return course;
    } catch (_) {
      return null;
    }
  }

  Future<bool> acceptInvitation(String courseId, String userId) async {
    final course = coursesBox.get(courseId);
    if (course == null) return false;
    final user = usersBox.get(userId);
    if (user == null) return false;
    if (!course.invitations.contains(user.email)) return false;
    if (!course.studentIds.contains(userId)) {
      course.studentIds.add(userId);
      // Regenerar grupos de todas las categorías de este curso
      for (final cat in categoriesBox.values.where((c) => c.courseId == course.id)) {
        await createGroupsForCategory(cat.id, onlyAssignNew: true, newStudentId: userId);
      }
    }
    course.invitations.remove(user.email);
    await coursesBox.put(course.id, course);
    notifyListeners();
    return true;
  }

  List<Course> listInvitationsForUser(String email) {
    return coursesBox.values.where((c) => c.invitations.contains(email)).toList();
  }

  Future<Category> createCategory(Category category) async {
  await categoriesBox.put(category.id, category);
  // Generar grupos automáticamente al crear la categoría
  await createGroupsForCategory(category.id);
  notifyListeners();
  return category;
  }

  Future<Category?> updateCategory(String id, {String? name, bool? randomAssign, int? studentsPerGroup}) async {
    final cat = categoriesBox.get(id);
    if (cat == null) return null;
    bool shouldRegenerate = false;
    if (name != null) cat.name = name;
    if (randomAssign != null && randomAssign != cat.randomAssign) {
      cat.randomAssign = randomAssign;
      shouldRegenerate = true;
    }
    if (studentsPerGroup != null && studentsPerGroup != cat.studentsPerGroup) {
      cat.studentsPerGroup = studentsPerGroup;
      shouldRegenerate = true;
    }
    await categoriesBox.put(cat.id, cat);
    if (shouldRegenerate) {
      await createGroupsForCategory(cat.id);
    }
    notifyListeners();
    return cat;
  }

  Future<bool> deleteCategory(String id) async {
    final cat = categoriesBox.get(id);
    if (cat == null) return false;
    final groupsToDelete = groupsBox.values.where((g) => g.categoryId == id).toList();
    for (final g in groupsToDelete) {
      await groupsBox.delete(g.id);
    }
    await categoriesBox.delete(id);
    notifyListeners();
    return true;
  }

  Future<List<Group>> createGroupsForCategory(String categoryId, {bool onlyAssignNew = false, String? newStudentId}) async {
    final cat = categoriesBox.get(categoryId);
    if (cat == null) return [];
    final course = coursesBox.get(cat.courseId);
    if (course == null) return [];

    final existing = groupsBox.values.where((g) => g.categoryId == categoryId).toList();
    final allStudents = List<String>.from(course.studentIds);
    final groupCount = (allStudents.length / cat.studentsPerGroup).ceil();
    List<Group> newGroups = [];

    if (onlyAssignNew && newStudentId != null) {
      // Solo asignar el nuevo estudiante
      if (cat.randomAssign) {
        // Buscar grupo con cupo
        List<Group> groups = existing.isNotEmpty ? List<Group>.from(existing) : [for (var i = 1; i <= groupCount; i++) Group(id: '${cat.id}_g$i', categoryId: cat.id, name: 'Grupo $i')];
        Group? groupWithSpace;
        for (final g in groups) {
          if (g.memberIds.length < cat.studentsPerGroup) {
            groupWithSpace = g;
            break;
          }
        }
        if (groupWithSpace == null) {
          // No hay grupo con cupo, crear uno nuevo
          final newGroup = Group(
            id: '${cat.id}_g${groups.length + 1}',
            categoryId: cat.id,
            name: 'Grupo ${groups.length + 1}',
            memberIds: [newStudentId],
          );
          await groupsBox.put(newGroup.id, newGroup);
        } else {
          groupWithSpace.memberIds.add(newStudentId);
          await groupsBox.put(groupWithSpace.id, groupWithSpace);
        }
      }
      // En modo libre no se asigna automáticamente
      notifyListeners();
      return groupsBox.values.where((g) => g.categoryId == categoryId).toList();
    }

    if (cat.randomAssign) {
      // Aleatorio: repartir todos los estudiantes aleatoriamente SOLO si cambia el tamaño o se crea la categoría
      allStudents.shuffle();
      int idx = 0;
      for (var i = 1; i <= groupCount; i++) {
        final members = allStudents.sublist(idx, (idx + cat.studentsPerGroup) > allStudents.length ? allStudents.length : idx + cat.studentsPerGroup);
        newGroups.add(Group(
          id: '${cat.id}_g$i',
          categoryId: cat.id,
          name: 'Grupo $i',
          memberIds: List<String>.from(members),
        ));
        idx += cat.studentsPerGroup;
      }
    } else {
      // Libre: mantener los grupos y estudiantes existentes si es posible
      for (var i = 1; i <= groupCount; i++) {
        final groupId = '${cat.id}_g$i';
        final existingGroup = existing.firstWhere(
          (g) => g.id == groupId,
          orElse: () => Group(id: groupId, categoryId: cat.id, name: 'Grupo $i'),
        );
        newGroups.add(Group(
          id: groupId,
          categoryId: cat.id,
          name: 'Grupo $i',
          memberIds: List<String>.from(existingGroup.memberIds),
        ));
      }
      for (final group in newGroups) {
        group.memberIds.removeWhere((id) => !allStudents.contains(id));
      }
      for (final group in newGroups) {
        if (group.memberIds.length > cat.studentsPerGroup) {
          group.memberIds = group.memberIds.sublist(0, cat.studentsPerGroup);
        }
      }
      // NO asignar automáticamente nuevos estudiantes en modo libre
    }
    for (final g in existing) {
      await groupsBox.delete(g.id);
    }
    for (final group in newGroups) {
      await groupsBox.put(group.id, group);
    }
    notifyListeners();
    return newGroups;

  }

  List<Group> listGroupsForCategory(String categoryId) {
    return groupsBox.values.where((g) => g.categoryId == categoryId).toList();
  }

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
