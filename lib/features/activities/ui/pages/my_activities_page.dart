import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../courses/ui/controllers/student_courses_controller.dart';
import '../../../courses/domain/models/course_model.dart';
import '../../../assessments/domain/models/activity_model.dart';
import '../../../assessments/ui/pages/activity_detail_page.dart';

class MyActivitiesPage extends StatefulWidget {
  const MyActivitiesPage({super.key});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage> {
  late final StudentCoursesController _studentCtrl;

  final _expanded = <String>{}.obs; // courseId set
  final Map<String, _CourseActivitiesState> _courseState = {}; // courseId -> state
  final Set<String> _loadingCourses = {}; // avoid duplicate loads

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StudentCoursesController>()) {
      Get.lazyPut<StudentCoursesController>(() => StudentCoursesController(
            joinByCodeUseCase: Get.find(),
            getStudentCoursesUseCase: Get.find(),
            getInvitedCoursesUseCase: Get.find(),
            acceptInvitationUseCase: Get.find(),
          ),
          fenix: true);
    }
    _studentCtrl = Get.find<StudentCoursesController>();
    _studentCtrl.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades')),
      body: Obx(() {
        final loading = _studentCtrl.loading.value;
        final courses = _studentCtrl.enrolled;
        if (loading) return const Center(child: CircularProgressIndicator());
        if (courses.isEmpty) return const Center(child: Text('No estás inscrito en ningún curso'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = courses[index];
            final expanded = _expanded.contains(c.id);
            final state = _courseState[c.id];
            // Eager load course activities so the panel opens ready
            if (state == null && !_loadingCourses.contains(c.id)) {
              _loadingCourses.add(c.id);
              Future.microtask(() async {
                try {
                  _courseState[c.id] = await _loadCourseActivities(courseId: c.id);
                } finally {
                  _loadingCourses.remove(c.id);
                  if (mounted) setState(() {});
                }
              });
            }
            return Card(
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
                              Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _toggleCourse(c),
                          icon: Icon(expanded ? Icons.expand_less : Icons.assignment_outlined),
                          label: Text(expanded ? 'Ocultar' : 'Ver actividades'),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _ActivitiesPanel(state: state),
                      ),
                      crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
    if (!_courseState.containsKey(id)) {
      _courseState[id] = _CourseActivitiesState(loading: true, activities: const []);
      if (mounted) setState(() {});
      try {
        _courseState[id] = await _loadCourseActivities(courseId: id);
      } finally {
        if (mounted) setState(() {});
      }
    }
  }

  Future<_CourseActivitiesState> _loadCourseActivities({required String courseId}) async {
    final abox = Hive.box(HiveBoxes.activities);
    final activities = <ActivityModel>[];
    for (final key in abox.keys) {
      final data = abox.get(key);
      if (data is Map && data['courseId'] == courseId) {
        final visible = data['visible'] as bool? ?? true;
        if (!visible) continue; // no mostrar a estudiantes si no es visible
        activities.add(ActivityModel(
          id: data['id'],
          courseId: data['courseId'],
          categoryId: data['categoryId'],
          name: data['name'],
          description: data['description'] ?? '',
          dueDate: data['dueDate'] != null ? DateTime.tryParse(data['dueDate']) : null,
          visible: visible,
        ));
      }
    }
    // ordenar por fecha (sin fecha al final)
    activities.sort((a, b) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return a.name.compareTo(b.name);
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return _CourseActivitiesState(loading: false, activities: activities);
  }
}

class _CourseActivitiesState {
  final bool loading;
  final List<ActivityModel> activities;
  _CourseActivitiesState({required this.loading, required this.activities});
}

class _ActivitiesPanel extends StatelessWidget {
  final _CourseActivitiesState? state;
  const _ActivitiesPanel({required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null || s.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (s.activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No hay actividades'),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: s.activities.length,
          separatorBuilder: (_, __) => const Divider(height: 8),
          itemBuilder: (context, i) {
            final a = s.activities[i];
            final info = _timeInfo(a.dueDate);
            return ListTile(
              leading: Icon(info.icon, color: info.color),
              title: Text(a.name),
              subtitle: a.description.isNotEmpty
                  ? Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis)
                  : null,
              trailing: SizedBox(
                width: 180,
                child: Text(
                  info.label,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: info.color, fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () => Get.to(() => ActivityDetailPage(activity: a)),
            );
          },
        ),
      ),
    );
  }

  _TimeInfo _timeInfo(DateTime? due) {
    if (due == null) {
      return _TimeInfo(label: 'Sin fecha límite', short: '—', color: Colors.grey, icon: Icons.info_outline);
    }
    final now = DateTime.now();
    final diff = due.difference(now);
    if (diff.isNegative) {
      final daysLate = diff.inDays.abs();
      final label = daysLate <= 0
          ? 'Retraso: menos de 1 día'
          : 'Retraso: $daysLate día${daysLate == 1 ? '' : 's'}';
      return _TimeInfo(label: label, short: 'Retraso', color: Colors.red, icon: Icons.warning_amber_rounded);
    }
    // Remaining
    final days = diff.inDays;
    final hours = (diff.inHours % 24);
    String label;
    if (days > 0) {
  label = 'Quedan: $days d $hours h';
    } else {
      final mins = (diff.inMinutes % 60);
  label = 'Quedan: ${diff.inHours} h $mins min';
    }
    final short = days > 0 ? '$days d' : '${diff.inHours} h';
    final color = days == 0 && diff.inHours <= 4 ? Colors.orange : Colors.green;
    final icon = days == 0 && diff.inHours <= 4 ? Icons.schedule : Icons.timer_outlined;
    return _TimeInfo(label: label, short: short, color: color, icon: icon);
  }
}

class _TimeInfo {
  final String label;
  final String short;
  final Color color;
  final IconData icon;
  _TimeInfo({required this.label, required this.short, required this.color, required this.icon});
}

