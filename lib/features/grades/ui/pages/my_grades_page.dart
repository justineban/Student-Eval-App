import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../courses/ui/controllers/student_courses_controller.dart';
import '../../../courses/domain/models/course_model.dart';
import '../../../assessments/domain/models/activity_model.dart';
import '../../../assessments/domain/models/assessment_model.dart';
import '../../../assessments/domain/models/peer_evaluation_model.dart';
import '../../../assessments/domain/use_cases/get_received_peer_evaluations_use_case.dart';
import '../../../assessments/data/datasources/peer_evaluation_local_datasource.dart';
import '../../../assessments/data/datasources/peer_evaluation_remote_roble_datasource.dart';
import '../../../assessments/data/repositories/peer_evaluation_repository_impl.dart';
import '../../../assessments/domain/repositories/peer_evaluation_repository.dart';

class MyGradesPage extends StatefulWidget {
  const MyGradesPage({super.key});
  @override
  State<MyGradesPage> createState() => _MyGradesPageState();
}

class _MyGradesPageState extends State<MyGradesPage> {
  late final AuthController _auth;
  late final StudentCoursesController _studentCtrl;
  late final GetReceivedPeerEvaluationsUseCase _getUseCase;

  final _expanded = <String>{}.obs; // courseId set
  final Map<String, _CourseGradesState> _courseState = {}; // courseId -> state
  final Set<String> _loadingCourses = {}; // track background loads to avoid duplicates

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
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
    // DI defensiva para obtener evaluaciones recibidas
    if (!Get.isRegistered<GetReceivedPeerEvaluationsUseCase>()) {
      if (!Get.isRegistered<PeerEvaluationRepository>()) {
        if (!Get.isRegistered<PeerEvaluationLocalDataSource>()) {
          Get.lazyPut<PeerEvaluationLocalDataSource>(() => HivePeerEvaluationLocalDataSource(), fenix: true);
        }
        if (!Get.isRegistered<PeerEvaluationRemoteDataSource>()) {
          Get.lazyPut<PeerEvaluationRemoteDataSource>(() => RoblePeerEvaluationRemoteDataSource(projectId: 'movil_993b654d20', debugLogging: true), fenix: true);
        }
        Get.lazyPut<PeerEvaluationRepository>(() => PeerEvaluationRepositoryImpl(
          remote: Get.find<PeerEvaluationRemoteDataSource>(),
          localCache: Get.find<PeerEvaluationLocalDataSource>(),
        ), fenix: true);
      }
      Get.lazyPut(() => GetReceivedPeerEvaluationsUseCase(Get.find<PeerEvaluationRepository>()), fenix: true);
    }
    _getUseCase = Get.find<GetReceivedPeerEvaluationsUseCase>();
    _studentCtrl.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis notas')),
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
            final courseAvg = state?.courseAverage;

            // Eagerly compute course averages on first render (without expanding)
            if (state == null && !_loadingCourses.contains(c.id)) {
              _loadingCourses.add(c.id);
              // Launch background load
              Future.microtask(() async {
                try {
                  final s = await _loadCourseGrades(courseId: c.id);
                  _courseState[c.id] = s;
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
                        if (courseAvg != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: _Badge(text: courseAvg.toStringAsFixed(1)),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _toggleCourse(c),
                          icon: Icon(expanded ? Icons.expand_less : Icons.list_alt_outlined),
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
      final state = _CourseGradesState(loading: true, activities: const [], grades: const {}, courseAverage: null);
      _courseState[id] = state;
      if (mounted) setState(() {});
      try {
        _courseState[id] = await _loadCourseGrades(courseId: id);
      } finally {
        if (mounted) setState(() {});
      }
    }
  }

  Future<_CourseGradesState> _loadCourseGrades({required String courseId}) async {
    final userId = _auth.currentUser.value?.id;
    if (userId == null) return _CourseGradesState(loading: false, activities: const [], grades: const {}, courseAverage: null);

    // Fetch activities for course
    final abox = Hive.box(HiveBoxes.activities);
    final activities = <ActivityModel>[];
    for (final key in abox.keys) {
      final data = abox.get(key);
      if (data is Map && data['courseId'] == courseId) {
        activities.add(ActivityModel(
          id: data['id'],
          courseId: data['courseId'],
          categoryId: data['categoryId'],
          name: data['name'],
          description: data['description'] ?? '',
          dueDate: data['dueDate'] != null ? DateTime.tryParse(data['dueDate']) : null,
          visible: data['visible'] as bool? ?? true,
        ));
      }
    }
    // Fetch assessment per activity (if any) and compute grade for the user as avg across received peer evaluations
    final Map<String, double> grades = {};
    final aBox = Hive.box(HiveBoxes.assessments);
    for (final act in activities) {
      AssessmentModel? asm;
      for (final key in aBox.keys) {
        final data = aBox.get(key);
        if (data is Map && data['activityId'] == act.id) {
          asm = AssessmentModel(
            id: data['id'],
            courseId: data['courseId'],
            activityId: data['activityId'],
            title: data['title'] ?? '',
            durationMinutes: data['durationMinutes'] ?? 60,
            startAt: DateTime.tryParse(data['startAt'] ?? '') ?? DateTime.now(),
            gradesVisible: data['gradesVisible'] as bool? ?? false,
            cancelled: data['cancelled'] as bool? ?? false,
          );
          break;
        }
      }
      if (asm == null || asm.cancelled == true) {
        continue; // no assessment or cancelled -> no grade
      }
      // Get received evaluations for this user in this assessment and compute average across all criteria and evaluators
      final evals = await _getUseCase(assessmentId: asm.id, evaluateeId: userId);
      if (evals.isEmpty) continue;
      double avg(num Function(PeerEvaluationModel) sel) {
        final sum = evals.fold<num>(0, (p, e) => p + sel(e));
        return sum / evals.length;
      }
      final p = avg((e) => e.punctuality);
      final c = avg((e) => e.contributions);
      final cm = avg((e) => e.commitment);
      final a = avg((e) => e.attitude);
      final comps = [p, c, cm, a];
      final actGrade = comps.reduce((x, y) => x + y) / comps.length;
      grades[act.id] = actGrade;
    }
    // Compute course average across activities with grade
    double? courseAvg;
    if (grades.isNotEmpty) {
      courseAvg = grades.values.reduce((x, y) => x + y) / grades.length;
    }
    return _CourseGradesState(loading: false, activities: activities, grades: grades, courseAverage: courseAvg);
  }
}

class _CourseGradesState {
  final bool loading;
  final List<ActivityModel> activities;
  final Map<String, double> grades; // activityId -> grade
  final double? courseAverage;
  _CourseGradesState({required this.loading, required this.activities, required this.grades, required this.courseAverage});
}

class _ActivitiesPanel extends StatelessWidget {
  final _CourseGradesState? state;
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
      constraints: const BoxConstraints(maxHeight: 360),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: s.activities.length,
          separatorBuilder: (_, __) => const Divider(height: 8),
          itemBuilder: (context, i) {
            final a = s.activities[i];
            final grade = s.grades[a.id];
            return ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(a.name),
              subtitle: Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: _Badge(text: grade == null ? '--' : grade.toStringAsFixed(1)),
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
  final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
  color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
