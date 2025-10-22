import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../assessments/domain/models/category_model.dart';
import '../../../assessments/domain/models/activity_model.dart';
import '../../../assessments/domain/models/assessment_model.dart';
import '../../../assessments/domain/models/peer_evaluation_model.dart';
import '../../../assessments/domain/use_cases/get_received_peer_evaluations_use_case.dart';
import '../../../assessments/data/datasources/peer_evaluation_local_datasource.dart';
import '../../../assessments/data/datasources/peer_evaluation_remote_roble_datasource.dart';
import '../../../assessments/data/repositories/peer_evaluation_repository_impl.dart';
import '../../../assessments/domain/repositories/peer_evaluation_repository.dart';
import '../../../courses/domain/models/group_model.dart';
import '../../../auth/data/datasources/user_remote_roble_datasource.dart';

class CategoryNotesPage extends StatefulWidget {
  final CategoryModel category;
  const CategoryNotesPage({super.key, required this.category});

  @override
  State<CategoryNotesPage> createState() => _CategoryNotesPageState();
}

class _CategoryNotesPageState extends State<CategoryNotesPage> {
  final Map<String, String?> _nameCache = {};
  late final GetReceivedPeerEvaluationsUseCase _getUseCase;

  bool _loading = true;
  List<ActivityModel> _activities = [];
  List<GroupModel> _groups = [];
  final Set<String> _expandedGroups = {};

  // studentId -> activityId -> grade
  final Map<String, Map<String, double?>> _studentGrades = {};

  @override
  void initState() {
    super.initState();
    // Ensure dependencies
    if (!Get.isRegistered<GetReceivedPeerEvaluationsUseCase>()) {
      if (!Get.isRegistered<PeerEvaluationRepository>()) {
        if (!Get.isRegistered<PeerEvaluationLocalDataSource>()) {
          Get.lazyPut<PeerEvaluationLocalDataSource>(
            () => HivePeerEvaluationLocalDataSource(),
            fenix: true,
          );
        }
        if (!Get.isRegistered<PeerEvaluationRemoteDataSource>()) {
          Get.lazyPut<PeerEvaluationRemoteDataSource>(
            () => RoblePeerEvaluationRemoteDataSource(
              projectId: 'movil_993b654d20',
              debugLogging: true,
            ),
            fenix: true,
          );
        }
        Get.lazyPut<PeerEvaluationRepository>(
          () => PeerEvaluationRepositoryImpl(
            remote: Get.find<PeerEvaluationRemoteDataSource>(),
            localCache: Get.find<PeerEvaluationLocalDataSource>(),
          ),
          fenix: true,
        );
      }
      Get.lazyPut(
        () => GetReceivedPeerEvaluationsUseCase(
          Get.find<PeerEvaluationRepository>(),
        ),
        fenix: true,
      );
    }
    _getUseCase = Get.find<GetReceivedPeerEvaluationsUseCase>();

    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final category = widget.category;

      // load activities for this category
      final abox = Hive.box(HiveBoxes.activities);
      final activities = <ActivityModel>[];
      for (final key in abox.keys) {
        final data = abox.get(key);
        if (data is Map && data['categoryId'] == category.id) {
          activities.add(
            ActivityModel(
              id: data['id'],
              courseId: data['courseId'],
              categoryId: data['categoryId'],
              name: data['name'],
              description: data['description'] ?? '',
              dueDate: data['dueDate'] != null
                  ? DateTime.tryParse(data['dueDate'])
                  : null,
              visible: data['visible'] as bool? ?? true,
            ),
          );
        }
      }

      // load groups for this category
      final gbox = Hive.box(HiveBoxes.groups);
      final groups = <GroupModel>[];
      for (final key in gbox.keys) {
        final data = gbox.get(key);
        if (data is Map && data['categoryId'] == category.id) {
          groups.add(
            GroupModel(
              id: data['id'],
              courseId: data['courseId'],
              categoryId: data['categoryId'],
              name: data['name'] ?? 'Grupo',
              memberIds: (data['memberIds'] as List?)?.cast<String>() ?? [],
            ),
          );
        }
      }

      setState(() {
        _activities = activities;
        _groups = groups;
      });

      // compute grades for each student in each group
      final allStudentIds = _groups.expand((g) => g.memberIds).toSet();
      final aBox = Hive.box(HiveBoxes.assessments);

      for (final sid in allStudentIds) {
        _studentGrades[sid] = {};
      }

      for (final act in _activities) {
        // find assessment for activity if any
        AssessmentModel? asm;
        for (final k in aBox.keys) {
          final d = aBox.get(k);
          if (d is Map && d['activityId'] == act.id) {
            asm = AssessmentModel(
              id: d['id'],
              courseId: d['courseId'],
              activityId: d['activityId'],
              title: d['title'] ?? '',
              durationMinutes: d['durationMinutes'] ?? 60,
              startAt: DateTime.tryParse(d['startAt'] ?? '') ?? DateTime.now(),
              gradesVisible: d['gradesVisible'] as bool? ?? false,
              cancelled: d['cancelled'] as bool? ?? false,
            );
            break;
          }
        }
        if (asm == null || asm.cancelled) {
          // No assessment -> grade remains null
          continue;
        }

        for (final sid in allStudentIds) {
          try {
            final evals = await _getUseCase(
              assessmentId: asm.id,
              evaluateeId: sid,
            );
            if (evals.isEmpty) {
              _studentGrades[sid]![act.id] = null;
              continue;
            }
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
            _studentGrades[sid]![act.id] = actGrade;
          } catch (_) {
            _studentGrades[sid]![act.id] = null;
          }
        }
      }

      // prefetch names
      final api = Get.find<UserRemoteDataSource>();
      await Future.wait(allStudentIds.map((id) async {
        try {
          _nameCache[id] = await api.fetchNameByUserId(id);
        } catch (_) {
          _nameCache[id] = null;
        }
      }));
    } catch (e, st) {
      debugPrint('Error building category notes: $e');
      debugPrint('$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _groupActivityAverage(String groupId, String activityId) {
    final g = _groups.firstWhere((g) => g.id == groupId);
    final vals = g.memberIds
        .map((sid) => _studentGrades[sid]?[activityId])
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((x, y) => x + y) / vals.length;
  }

  double? _groupAverageAcrossActivities(String groupId) {
    final vals = _activities
        .map((a) => _groupActivityAverage(groupId, a.id))
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((x, y) => x + y) / vals.length;
  }

  double? _activityAverageAcrossGroups(String activityId) {
    final vals = _groups
        .map((g) => _groupActivityAverage(g.id, activityId))
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((x, y) => x + y) / vals.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Notas de ${widget.category.name}'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? const Center(child: Text('No hay actividades en esta categoría'))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 220,
                                    child: Text(
                                      'Estudiante / Grupo',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  for (final a in _activities)
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        a.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  const SizedBox(
                                    width: 120,
                                    child: Text(
                                      'Promedio',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Groups and students rows (group rows are expandable)
                              for (final g in _groups) ...[
                                // Group row (tap to expand/collapse)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (_expandedGroups.contains(g.id)) {
                                          _expandedGroups.remove(g.id);
                                        } else {
                                          _expandedGroups.add(g.id);
                                        }
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 220,
                                          child: Row(
                                            children: [
                                              Icon(
                                                _expandedGroups.contains(g.id)
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  g.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        for (final a in _activities)
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              _groupActivityAverage(g.id, a.id)
                                                      ?.
                                                      toStringAsFixed(1) ??
                                                  '--',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            _groupAverageAcrossActivities(g.id)
                                                    ?.
                                                    toStringAsFixed(1) ??
                                                '--',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Student rows for this group (only visible when expanded)
                                if (_expandedGroups.contains(g.id))
                                  for (final sid in g.memberIds)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 220,
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 26),
                                                Expanded(
                                                  child: Text(_nameCache[sid] ?? sid),
                                                ),
                                              ],
                                            ),
                                          ),
                                          for (final a in _activities)
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                _studentGrades[sid]?[a.id]
                                                        ?.
                                                        toStringAsFixed(1) ??
                                                    '--',
                                              ),
                                            ),
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              (() {
                                                final vals = _activities
                                                    .map((a) =>
                                                        _studentGrades[sid]?[a.id])
                                                    .whereType<double>()
                                                    .toList();
                                                if (vals.isEmpty) return '--';
                                                final v = vals
                                                        .reduce((x, y) => x + y) /
                                                    vals.length;
                                                return v.toStringAsFixed(1);
                                              })(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                              const SizedBox(height: 12),
                              // Final summary row with activity averages
                              Row(
                                children: [
                                  SizedBox(
                                    width: 220,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 26),
                                      child: const Text(
                                        'Promedio',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  for (final a in _activities)
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        _activityAverageAcrossGroups(a.id)
                                                ?.
                                                toStringAsFixed(1) ??
                                            '--',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  const SizedBox(
                                    width: 120,
                                    child: SizedBox(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // (Removed duplicated 'Promedio por actividad' section)
                    ],
                  ),
                ),
    );
  }
}

// _Badge removed: no longer used in this page after layout changes
