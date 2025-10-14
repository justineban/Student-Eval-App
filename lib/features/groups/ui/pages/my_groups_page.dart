import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../auth/data/datasources/user_remote_roble_datasource.dart';
import '../../../courses/ui/controllers/student_courses_controller.dart';
import '../../../courses/domain/models/course_model.dart';

class MyGroupsPage extends StatefulWidget {
  const MyGroupsPage({super.key});

  @override
  State<MyGroupsPage> createState() => _MyGroupsPageState();
}

class _MyGroupsPageState extends State<MyGroupsPage> {
  late final AuthController _auth;
  late final StudentCoursesController _studentCtrl;
  // no local auth datasource needed for name lookups

  final _expanded = <String>{}.obs; // courseId set
  final _loadingCourseGroups = <String>{}.obs; // courseIds loading
  final Map<String, List<_UserGroupInfo>> _courseGroups =
      {}; // courseId -> groups

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  // _authLocal = Get.find<AuthLocalDataSource>();
    // Defensive DI for StudentCoursesController in case not registered yet
    if (!Get.isRegistered<StudentCoursesController>()) {
      Get.lazyPut<StudentCoursesController>(
        () => StudentCoursesController(
          joinByCodeUseCase: Get.find(),
          getStudentCoursesUseCase: Get.find(),
          getInvitedCoursesUseCase: Get.find(),
          acceptInvitationUseCase: Get.find(),
        ),
        fenix: true,
      );
    }
    _studentCtrl = Get.find<StudentCoursesController>();
    // Load enrolled courses
    _studentCtrl.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Mis grupos'),
      body: Obx(() {
        final loading = _studentCtrl.loading.value;
        final courses = _studentCtrl.enrolled;
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (courses.isEmpty) {
          return const Center(child: Text('No estás inscrito en ningún curso'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = courses[index];
            final expanded = _expanded.contains(c.id);
            final isLoadingGroups = _loadingCourseGroups.contains(c.id);
            final groups = _courseGroups[c.id] ?? const <_UserGroupInfo>[];
            return Material(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _toggleCourse(c),
                          icon: Icon(
                            expanded
                                ? Icons.expand_less
                                : Icons.groups_outlined,
                          ),
                          label: Text(expanded ? 'Ocultar' : 'Ver grupos'),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _GroupsPanel(
                          isLoading: isLoadingGroups,
                          groups: groups,
                          onViewMembers: _openMembersDialog,
                        ),
                      ),
                      crossFadeState: expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _toggleCourse(CourseModel course) async {
    final id = course.id;
    if (_expanded.contains(id)) {
      _expanded.remove(id);
      _expanded.refresh();
      if (mounted) setState(() {});
      return;
    }
    _expanded.add(id);
    _expanded.refresh();
    if (mounted) setState(() {});
    // If not loaded yet, load
    if (!_courseGroups.containsKey(id)) {
      _loadingCourseGroups.add(id);
      _loadingCourseGroups.refresh();
      try {
        final groups = await _loadUserGroupsForCourse(courseId: id);
        _courseGroups[id] = groups;
      } finally {
        _loadingCourseGroups.remove(id);
        _loadingCourseGroups.refresh();
        if (mounted) setState(() {});
      }
    }
  }

  Future<List<_UserGroupInfo>> _loadUserGroupsForCourse({
    required String courseId,
  }) async {
    final userId = _auth.currentUser.value?.id;
    if (userId == null) return <_UserGroupInfo>[];

    final gbox = Hive.box(HiveBoxes.groups);
    final cbox = Hive.box(HiveBoxes.categories);
    // Build a map categoryId -> categoryName for fast lookup
    final Map<String, String> catNames = {};
    for (final key in cbox.keys) {
      final data = cbox.get(key);
      if (data is Map && data['courseId'] == courseId) {
        catNames[data['id'] as String] =
            (data['name'] as String?) ?? 'Sin categoría';
      }
    }

    final List<_UserGroupInfo> mine = [];
    for (final key in gbox.keys) {
      final data = gbox.get(key);
      if (data is Map && data['courseId'] == courseId) {
        final members =
            (data['memberIds'] as List?)?.cast<String>() ?? const <String>[];
        if (members.contains(userId)) {
          final gid = data['id'] as String;
          final name = (data['name'] as String?) ?? 'Grupo';
          final categoryId = data['categoryId'] as String?;
          final categoryName = categoryId == null
              ? 'Sin categoría'
              : (catNames[categoryId] ?? 'Sin categoría');
          mine.add(
            _UserGroupInfo(
              groupId: gid,
              groupName: name,
              categoryName: categoryName,
              memberIds: members,
            ),
          );
        }
      }
    }
    // Sort by category, then group name
    mine.sort((a, b) {
      final byCat = a.categoryName.compareTo(b.categoryName);
      if (byCat != 0) return byCat;
      return a.groupName.compareTo(b.groupName);
    });
    return mine;
  }

  void _openMembersDialog(_UserGroupInfo info) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Integrantes • ${info.groupName}'),
          content: SizedBox(
            width: 360,
            child: FutureBuilder<List<String>>(
              future: _fetchNames(info.memberIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final names = snapshot.data ?? const <String>[];
                if (names.isEmpty) {
                  return const Text('Sin integrantes');
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: names.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, i) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text(names[i]),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _fetchNames(List<String> ids) async {
    final List<String> out = [];
    for (final id in ids) {
      try {
        final name = await Get.find<UserRemoteDataSource>().fetchNameByUserId(id);
        out.add((name == null || name.trim().isEmpty) ? id : name);
      } catch (_) {
        out.add(id);
      }
    }
    return out;
  }
}

class _GroupsPanel extends StatelessWidget {
  final bool isLoading;
  final List<_UserGroupInfo> groups;
  final void Function(_UserGroupInfo info) onViewMembers;
  const _GroupsPanel({
    required this.isLoading,
    required this.groups,
    required this.onViewMembers,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text('No perteneces a ningún grupo en este curso'),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: groups.length,
          separatorBuilder: (_, __) => const Divider(height: 8),
          itemBuilder: (context, i) {
            final g = groups[i];
            return ListTile(
              leading: const Icon(Icons.group_outlined),
              title: Text(g.groupName),
              subtitle: Text(g.categoryName),
              trailing: OutlinedButton(
                onPressed: () => onViewMembers(g),
                child: const Text('Ver integrantes'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserGroupInfo {
  final String groupId;
  final String groupName;
  final String categoryName;
  final List<String> memberIds;
  _UserGroupInfo({
    required this.groupId,
    required this.groupName,
    required this.categoryName,
    required this.memberIds,
  });
}
